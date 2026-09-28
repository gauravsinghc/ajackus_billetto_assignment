module Voting
  class Vote < ApplicationRecord
    self.table_name = 'voting_votes'
    include EventStoreInjector
    def cast!(user_id:, vote_type:)
      self.vote_type = vote_type
      save!
      event_store.publish(
        Voting::Events::VoteCast.strict(data: { event_id: event_id, user_id: user_id, vote_type: vote_type })
      )
    end
    def remove!(user_id:)
      destroy!
      event_store.publish(
        Voting::Events::VoteRemoved.strict(data: { event_id: event_id, user_id: user_id })
      )
    end
  end
end
