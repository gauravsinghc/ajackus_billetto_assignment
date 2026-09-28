module Voting
  module Commands
    class CastVote
      include ActiveModel::Model
      include ActiveModel::Attributes
      attribute :event_id, :string
      attribute :user_id, :string
      attribute :vote_type, :string
      validates :event_id, :user_id, :vote_type, presence: true
      validates :vote_type, inclusion: { in: %w[upvote downvote] }
    end
  end
end