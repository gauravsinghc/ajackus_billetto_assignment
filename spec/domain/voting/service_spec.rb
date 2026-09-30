require 'rails_helper'

RSpec.describe Voting::Service do
  before do
    allow(Event).to receive(:exists?).and_return(true)
  end
  let(:service) { described_class.new }
  let(:event_store) { Rails.configuration.event_store }

  describe "cast_vote" do
    it "creates an upvote" do
      cmd = Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "upvote")
      service.cast_vote(cmd)
      expect(Voting::Vote.find_by(event_id: "E1", user_id: "U1").vote_type).to eq("upvote")
    end

    it "creates a downvote" do
      cmd = Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "downvote")
      service.cast_vote(cmd)
      expect(Voting::Vote.find_by(event_id: "E1", user_id: "U1").vote_type).to eq("downvote")
    end

    it "rejects invalid vote type" do
      cmd = Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "invalid")
      expect { service.cast_vote(cmd) }.to raise_error(ActiveModel::ValidationError)
    end

    it "repeated identical vote is idempotent" do
      cmd = Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "upvote")
      service.cast_vote(cmd)
      
      expect {
        service.cast_vote(cmd)
      }.not_to change { Voting::Vote.count }
      
      # Should only publish one event to both main and linked streams
      main_stream = event_store.read.stream("Vote$E1-U1").to_a
      expect(main_stream.size).to eq(1)
      
      linked_stream = event_store.read.stream("Event$E1").to_a
      expect(linked_stream.size).to eq(1)
      
      # Both streams should reference the exact same event
      expect(main_stream.first.event_id).to eq(linked_stream.first.event_id)
    end

    it "changing upvote to downvote works" do
      service.cast_vote(Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "upvote"))
      service.cast_vote(Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "downvote"))
      expect(Voting::Vote.find_by(event_id: "E1", user_id: "U1").vote_type).to eq("downvote")
    end
    
    it "changing downvote to upvote works" do
      service.cast_vote(Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "downvote"))
      service.cast_vote(Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "upvote"))
      expect(Voting::Vote.find_by(event_id: "E1", user_id: "U1").vote_type).to eq("upvote")
    end
  end

  describe "event existence validation" do
    it "rejects cast_vote when event does not exist" do
      allow(Event).to receive(:exists?).with(billetto_event_id: "fake_id").and_return(false)
      cmd = Voting::Commands::CastVote.new(event_id: "fake_id", user_id: "U1", vote_type: "upvote")
      expect { service.cast_vote(cmd) }.to raise_error(Voting::EventNotFoundError)
    end

    it "rejects remove_vote when event does not exist" do
      allow(Event).to receive(:exists?).with(billetto_event_id: "fake_id").and_return(false)
      cmd = Voting::Commands::RemoveVote.new(event_id: "fake_id", user_id: "U1")
      expect { service.remove_vote(cmd) }.to raise_error(Voting::EventNotFoundError)
    end
  end

  describe "concurrent vote retry logic" do
    it "retries once on ActiveRecord::RecordNotUnique and updates the vote if intent differs" do
      cmd = Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "downvote")
      
      call_count = 0
      original_find = Voting::Vote.method(:find_or_initialize_by)
      
      allow(Voting::Vote).to receive(:find_or_initialize_by) do |args|
        if call_count == 0
          call_count += 1
          # First pass: simulate new record but cast! hits unique constraint
          vote = Voting::Vote.new(args)
          allow(vote).to receive(:cast!).and_raise(ActiveRecord::RecordNotUnique)
          vote
        else
          # Retry pass: simulate concurrent thread already inserted an upvote
          Voting::Vote.create!(event_id: "E1", user_id: "U1", vote_type: "upvote")
          original_find.call(args)
        end
      end
      
      service.cast_vote(cmd)
      
      expect(Voting::Vote.find_by(event_id: "E1", user_id: "U1").vote_type).to eq("downvote")
    end
  end

  describe "remove_vote" do
    it "removes existing vote" do
      service.cast_vote(Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "upvote"))
      cmd = Voting::Commands::RemoveVote.new(event_id: "E1", user_id: "U1")
      
      expect {
        service.remove_vote(cmd)
      }.to change { Voting::Vote.count }.by(-1)
      expect(Voting::Vote.find_by(event_id: "E1", user_id: "U1")).to be_nil
    end

    it "expected behavior when vote doesn't exist" do
      cmd = Voting::Commands::RemoveVote.new(event_id: "E1", user_id: "U1")
      
      expect {
        service.remove_vote(cmd)
      }.not_to change { Voting::Vote.count }
      
      # Should not publish RemoveVote to either stream
      main_stream = event_store.read.stream("Vote$E1-U1").to_a
      expect(main_stream).to be_empty
      
      linked_stream = event_store.read.stream("Event$E1").to_a
      # It might have events from previous tests depending on DB cleaner, but for U1 it shouldn't have RemoveVote
      # We specifically verify that the latest event is not a VoteRemoved
      if linked_stream.any?
        expect(linked_stream.last).not_to be_a(Voting::Events::VoteRemoved)
      end
    end
  end
end
