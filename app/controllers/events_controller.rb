class EventsController < ApplicationController
  def index
    @pagy, @events = pagy(Event.order(start_at: :asc), limit: 12)
    
    event_ids = @events.map(&:billetto_event_id)

    @vote_counts = EventVoteCount.where(event_id: event_ids).index_by(&:event_id)

    if current_user
      @user_votes = Voting::Vote.where(user_id: current_user[:id], event_id: event_ids).index_by(&:event_id)
    else
      @user_votes = {}
    end
  end
end
