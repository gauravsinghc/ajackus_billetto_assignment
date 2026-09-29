module Voting
  def self.subscriptions
    {
      ReadModels::UpdateEventVoteCount => [
        Voting::Events::VoteCast,
        Voting::Events::VoteRemoved
      ]
    }
  end
end