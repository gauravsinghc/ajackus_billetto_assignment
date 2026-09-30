module Voting
  class Service
    include Command::Handler
    handles Commands::CastVote, :cast_vote
    handles Commands::RemoveVote, :remove_vote

    def cast_vote(cmd)
      raise ActiveModel::ValidationError, cmd unless cmd.valid?
      
      begin
        vote = Voting::Vote.find_or_initialize_by(event_id: cmd.event_id, user_id: cmd.user_id)
        
        return if vote.persisted? && vote.vote_type == cmd.vote_type 
        vote.cast!(user_id: cmd.user_id, vote_type: cmd.vote_type)
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end

    def remove_vote(cmd)
      raise ActiveModel::ValidationError, cmd unless cmd.valid?
      vote = Voting::Vote.find_by(event_id: cmd.event_id, user_id: cmd.user_id)
      
      return unless vote 
      vote.remove!(user_id: cmd.user_id)
    end
  end
end