require 'rails_helper'

RSpec.describe "Voting Domain Events" do
  describe Voting::Events::VoteCast do
    it "requires valid schema" do
      expect {
        Voting::Events::VoteCast.strict(data: { event_id: "1", user_id: "2" })
      }.to raise_error(ArgumentError)
      
      expect {
        Voting::Events::VoteCast.strict(data: { event_id: "1", user_id: "2", vote_type: "upvote" })
      }.not_to raise_error
    end

    it "defines correct stream names" do
      event = Voting::Events::VoteCast.strict(data: { event_id: "E1", user_id: "U2", vote_type: "upvote" })
      expect(event.stream_names).to eq(["Vote$E1-U2", "Event$E1"])
    end
  end

  describe Voting::Events::VoteRemoved do
    it "requires valid schema" do
      expect {
        Voting::Events::VoteRemoved.strict(data: { event_id: "1" })
      }.to raise_error(ArgumentError)
    end

    it "defines correct stream names" do
      event = Voting::Events::VoteRemoved.strict(data: { event_id: "E1", user_id: "U2" })
      expect(event.stream_names).to eq(["Vote$E1-U2", "Event$E1"])
    end
  end
end
