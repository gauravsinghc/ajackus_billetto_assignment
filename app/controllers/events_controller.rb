class EventsController < ApplicationController
  def index
    @pagy, @events = pagy(Event.order(start_at: :asc), limit: 12)
  end
end
