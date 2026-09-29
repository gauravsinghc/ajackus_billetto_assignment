module ReadModels
  class UpdateEventVoteCount
    def self.call(event)
      new.call(event)
    end

    def call(event)
      event_id = event.data.fetch(:event_id)
      stream_name = event.stream_names.first

      event_history = Rails.configuration.event_store.read.stream(stream_name).to_a

      current_index = event_history.index { |e| e.event_id == event.event_id }
      
      return unless current_index

      previous_event = current_index > 0 ? event_history[current_index - 1] : nil

      previous_state = parse_state(previous_event)
      current_state  = parse_state(event)

      delta_up = 0
      delta_down = 0

      delta_up -= 1 if previous_state == :upvote
      delta_down -= 1 if previous_state == :downvote

      delta_up += 1 if current_state == :upvote
      delta_down += 1 if current_state == :downvote

      ApplicationRecord.transaction do
        sql1 = ActiveRecord::Base.sanitize_sql_array([<<~SQL, event.event_id])
          INSERT INTO projected_events (event_uuid, created_at)
          VALUES (?, NOW())
          ON CONFLICT (event_uuid) DO NOTHING;
        SQL
        result = ApplicationRecord.connection.execute(sql1)

        return if result.cmd_tuples == 0

        return if delta_up == 0 && delta_down == 0

        sql2 = ActiveRecord::Base.sanitize_sql_array([<<~SQL, event_id, delta_up, delta_down])
          INSERT INTO event_vote_counts (event_id, upvotes, downvotes, created_at, updated_at)
          VALUES (?, ?, ?, NOW(), NOW())
          ON CONFLICT (event_id) 
          DO UPDATE SET 
            upvotes = event_vote_counts.upvotes + EXCLUDED.upvotes,
            downvotes = event_vote_counts.downvotes + EXCLUDED.downvotes,
            updated_at = NOW();
        SQL
        ApplicationRecord.connection.execute(sql2)
      end
    end

    private

    def parse_state(event)
      return :none if event.nil? || event.instance_of?(Voting::Events::VoteRemoved)
      event.data.fetch(:vote_type).to_sym
    end
  end
end
