require 'rails_helper'

RSpec.describe ReadModels::UpdateEventVoteCount, type: :job do
  let(:event_store) { Rails.configuration.event_store }
  let(:event_id) { "E123" }
  let(:user_id) { "U456" }
  let(:stream_name) { "Vote$#{event_id}-#{user_id}" }

  before do
    ApplicationRecord.connection.execute("TRUNCATE TABLE event_vote_counts")
    ApplicationRecord.connection.execute("TRUNCATE TABLE projected_events")
  end

  def publish_event(event_class, vote_type: nil)
    data = { event_id: event_id, user_id: user_id }
    data[:vote_type] = vote_type if vote_type
    event = event_class.new(data: data)
    event_store.publish(event, stream_name: stream_name)
    event
  end

  def current_counts
    result = ApplicationRecord.connection.execute("SELECT upvotes, downvotes FROM event_vote_counts WHERE event_id = '#{event_id}'").first
    return { upvotes: 0, downvotes: 0 } unless result
    { upvotes: result["upvotes"], downvotes: result["downvotes"] }
  end

  describe "Basic counts" do
    it "none -> upvote increments upvotes" do
      event = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      described_class.new.call(event)
      expect(current_counts).to eq({ upvotes: 1, downvotes: 0 })
    end

    it "none -> downvote increments downvotes" do
      event = publish_event(Voting::Events::VoteCast, vote_type: "downvote")
      described_class.new.call(event)
      expect(current_counts).to eq({ upvotes: 0, downvotes: 1 })
    end
  end

  describe "Vote changes" do
    it "upvote -> downvote safely transitions" do
      event1 = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      described_class.new.call(event1)
      
      event2 = publish_event(Voting::Events::VoteCast, vote_type: "downvote")
      described_class.new.call(event2)
      
      expect(current_counts).to eq({ upvotes: 0, downvotes: 1 })
    end

    it "downvote -> upvote safely transitions" do
      event1 = publish_event(Voting::Events::VoteCast, vote_type: "downvote")
      described_class.new.call(event1)
      
      event2 = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      described_class.new.call(event2)
      
      expect(current_counts).to eq({ upvotes: 1, downvotes: 0 })
    end
  end

  describe "Removal" do
    it "upvote -> remove safely decrements upvotes" do
      event1 = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      described_class.new.call(event1)
      
      event2 = publish_event(Voting::Events::VoteRemoved)
      described_class.new.call(event2)
      
      expect(current_counts).to eq({ upvotes: 0, downvotes: 0 })
    end

    it "downvote -> remove safely decrements downvotes" do
      event1 = publish_event(Voting::Events::VoteCast, vote_type: "downvote")
      described_class.new.call(event1)
      
      event2 = publish_event(Voting::Events::VoteRemoved)
      described_class.new.call(event2)
      
      expect(current_counts).to eq({ upvotes: 0, downvotes: 0 })
    end
  end

  describe "Same vote" do
    it "upvote -> upvote produces no count change" do
      event1 = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      described_class.new.call(event1)
      
      event2 = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      described_class.new.call(event2)
      
      expect(current_counts).to eq({ upvotes: 1, downvotes: 0 })
    end
  end

  describe "Idempotency (Duplicate event delivery)" do
    it "delivering the exact same event twice only counts once" do
      event = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      
      described_class.new.call(event)
      expect(current_counts).to eq({ upvotes: 1, downvotes: 0 })
      
      # Duplicate delivery of the exact same event object (same UUID)
      described_class.new.call(event)
      expect(current_counts).to eq({ upvotes: 1, downvotes: 0 })
    end
  end

  describe "Zero-delta behavior" do
    it "records the event in projected_events without changing event_vote_counts (testing zero-delta projector behavior, not same-vote idempotency)" do
      # Cast a vote
      event1 = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      described_class.new.call(event1)
      expect(current_counts).to eq({ upvotes: 1, downvotes: 0 })
      
      # Deliver an event with the exact same net state but a new UUID
      event2 = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      described_class.new.call(event2)
      
      expect(current_counts).to eq({ upvotes: 1, downvotes: 0 })
      
      # Verify it WAS recorded in projected_events
      expect(ProjectedEvent.exists?(event_uuid: event2.event_id)).to be true
    end
  end

  describe "Failure and retry" do
    it "rolls back projected_events if counter update fails, allowing retry" do
      event = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      
      # Mock the DB connection to fail during the UPSERT
      allow(ApplicationRecord.connection).to receive(:execute).and_call_original
      allow(ApplicationRecord.connection).to receive(:execute)
        .with(/INSERT INTO event_vote_counts/)
        .and_raise(StandardError, "DB failure")
        
      expect {
        described_class.new.call(event)
      }.to raise_error(StandardError, "DB failure")
      
      # Verify transaction rolled back the deduplication marker
      projected = ApplicationRecord.connection.execute("SELECT * FROM projected_events WHERE event_uuid = '#{event.event_id}'").to_a
      expect(projected).to be_empty
      
      # Remove mock and retry
      allow(ApplicationRecord.connection).to receive(:execute).and_call_original
      described_class.new.call(event)
      
      expect(current_counts).to eq({ upvotes: 1, downvotes: 0 })
    end
  end

  describe "Replay" do
    it "can completely rebuild counts from Event Store history" do
      # 1. Generate some history
      e1 = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      e2 = publish_event(Voting::Events::VoteCast, vote_type: "downvote")
      e3 = publish_event(Voting::Events::VoteRemoved)
      e4 = publish_event(Voting::Events::VoteCast, vote_type: "upvote")
      
      # 2. Clear the read model completely
      ApplicationRecord.connection.execute("TRUNCATE TABLE event_vote_counts")
      ApplicationRecord.connection.execute("TRUNCATE TABLE projected_events")
      
      # 3. Replay
      events = event_store.read.of_type(["Voting::Events::VoteCast", "Voting::Events::VoteRemoved"]).forward.each
      events.each do |e|
        described_class.new.call(e)
      end
      
      # 4. Verify Final State
      expect(current_counts).to eq({ upvotes: 1, downvotes: 0 })
    end
  end
end
