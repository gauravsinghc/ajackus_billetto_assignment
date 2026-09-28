class EventsController < ApplicationController
  def index
    # Order by start_at ascending so upcoming events show first
    @pagy, @events = pagy(Event.order(start_at: :asc), limit: 12)
  end
end
