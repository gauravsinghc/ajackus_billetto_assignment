class VotesController < ApplicationController
  before_action :require_user!

  def create
    command = Voting::Commands::CastVote.new(
      event_id: params[:event_id],
      user_id: current_user[:id],
      vote_type: params[:vote_type]
    )
    # Note: Concurrent double-clicks (ActiveRecord::RecordNotUnique) are caught 
    # and swallowed inside Voting::Service to ensure idempotent success here.
    command_bus.call(command)

    redirect_to root_path, notice: "Vote cast successfully."
  rescue ActiveModel::ValidationError, Voting::EventNotFoundError
    redirect_to root_path, alert: "Invalid vote parameters."
  end

  def destroy
    command = Voting::Commands::RemoveVote.new(
      event_id: params[:event_id],
      user_id: current_user[:id]
    )
    command_bus.call(command)

    redirect_to root_path, notice: "Vote removed."
  rescue ActiveModel::ValidationError, Voting::EventNotFoundError
    redirect_to root_path, alert: "Invalid vote parameters."
  end

  private

  def require_user!
    redirect_to events_path, alert: "Must be logged in" unless current_user
  end
end
