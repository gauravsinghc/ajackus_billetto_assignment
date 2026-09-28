require 'rails_helper'

RSpec.describe Voting::Vote, type: :model do
  describe "database constraints" do
    it "enforces unique (event_id, user_id) constraint" do
      Voting::Vote.create!(event_id: "E1", user_id: "U1", vote_type: "upvote")
      
      expect {
        # Using raw insert to bypass validations (if any existed) and hit the DB constraint directly
        Voting::Vote.create(event_id: "E1", user_id: "U1", vote_type: "downvote")
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "prevents race conditions via true threaded concurrency", skip_transaction: true do
      # Disabling transactional fixtures for this test specifically (if needed) or relying on raw connections
      # Using Threads to attempt concurrent inserts
      
      threads = []
      
      # We'll try to insert 5 simultaneous requests for the same user/event
      5.times do |i|
        threads << Thread.new do
          begin
            # Use raw connection if needed, but ActiveRecord handles connection pooling
            Voting::Vote.create(event_id: "E99", user_id: "U99", vote_type: "upvote")
          rescue ActiveRecord::RecordNotUnique
            # This is expected for all but one thread
          end
        end
      end
      
      threads.each(&:join)
      
      # The database must enforce exactly 1 current vote
      expect(Voting::Vote.where(event_id: "E99", user_id: "U99").count).to eq(1)
    end
  end
end
