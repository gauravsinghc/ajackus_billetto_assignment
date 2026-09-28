module Voting
  module Events
    class VoteCast < Fact
      SCHEMA = {
        event_id: String,
        user_id: String,
        vote_type: String
      }.freeze
      def stream_names
        [
          "Vote$#{data.fetch(:event_id)}-#{data.fetch(:user_id)}",
          "Event$#{data.fetch(:event_id)}"
        ]
      end
    end
  end
end