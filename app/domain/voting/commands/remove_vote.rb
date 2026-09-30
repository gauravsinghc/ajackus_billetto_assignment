module Voting
  module Commands
    class RemoveVote
      include ActiveModel::Model
      include ActiveModel::Attributes
      attribute :event_id, :string
      attribute :user_id, :string
      validates :event_id, :user_id, presence: true
      validate :event_must_exist
      
      private

      def event_must_exist
        errors.add(:event_id, "must belong to a real event") unless Event.exists?(billetto_event_id: event_id)
      end
    end
  end
end