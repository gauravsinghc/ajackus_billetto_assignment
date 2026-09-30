require 'rails_helper'

RSpec.describe SimpleCommandBus do
  before do
    allow(Event).to receive(:exists?).and_return(true)
  en
  let(:bus) { Rails.configuration.command_bus }
  let(:event_store) { Rails.configuration.event_store }

  it "executes inside a transaction and attaches correlation_id to published events" do
    cmd = Voting::Commands::CastVote.new(event_id: "E1", user_id: "U1", vote_type: "upvote")
    
    # Execute the command
    bus.call(cmd)
    
    # Read the event
    events = event_store.read.stream("Vote$E1-U1").to_a
    expect(events.size).to eq(1)
    
    event = events.first
    expect(event.metadata[:correlation_id]).to be_present
  end

  it "rolls back DB and event store state atomically if link fails" do
    cmd = Voting::Commands::CastVote.new(event_id: "E2", user_id: "U2", vote_type: "upvote")
    
    # Mock EventStore link to raise an exception
    allow_any_instance_of(RailsEventStore::Client).to receive(:link).and_raise(StandardError, "Link failed")
    
    expect {
      bus.call(cmd)
    }.to raise_error(StandardError, "Link failed")
    
    # Verify DB rollback
    expect(Voting::Vote.find_by(event_id: "E2", user_id: "U2")).to be_nil
    
    # Verify main stream rollback (no event was persisted)
    expect(event_store.read.stream("Vote$E2-U2").to_a).to be_empty
    
    # Verify linked stream rollback
    expect(event_store.read.stream("Event$E2").to_a).to be_empty
  end
end
