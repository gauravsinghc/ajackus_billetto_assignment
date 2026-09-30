module Voting
  class EventNotFoundError < StandardError; end

  class Service
    include Command::Handler
    handles Commands::CastVote, :cast_vote
    handles Commands::RemoveVote, :remove_vote

    def cast_vote(cmd)
      raise ActiveModel::ValidationError, cmd unless cmd.valid?
      raise EventNotFoundError, "Event not found" unless Event.exists?(billetto_event_id: cmd.event_id)
      
      retries = 0
      begin
        vote = Voting::Vote.find_or_initialize_by(event_id: cmd.event_id, user_id: cmd.user_id)
        
        return if vote.persisted? && vote.vote_type == cmd.vote_type 
        vote.cast!(user_id: cmd.user_id, vote_type: cmd.vote_type)
      rescue ActiveRecord::RecordNotUnique
        if retries == 0
          retries += 1
          retry
        else
          raise
        end
      end
    end

    def remove_vote(cmd)
      raise ActiveModel::ValidationError, cmd unless cmd.valid?
      raise EventNotFoundError, "Event not found" unless Event.exists?(billetto_event_id: cmd.event_id)
      
      vote = Voting::Vote.find_by(event_id: cmd.event_id, user_id: cmd.user_id)
      
      return unless vote 
      vote.remove!(user_id: cmd.user_id)
    end
  end
end