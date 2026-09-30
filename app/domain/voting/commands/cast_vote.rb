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
      validate :event_must_exist

      private

      def event_must_exist
        errors.add(:event_id, "must belong to a real event") unless Event.exists?(billetto_event_id: event_id)
      end
    end
  end
end