require 'rails_helper'

RSpec.describe "Votes Security", type: :request do
  let!(:event) do
    Event.create!(
      billetto_event_id: "sec-event-456",
      title: "Security Test Event",
      start_at: 1.day.from_now,
      state: "published",
      last_seen_at: Time.current
    )
  end

  describe "POST /events/:event_id/vote" do
    it "refuses unauthenticated users and prevents side effects" do
      initial_vote_count = Voting::Vote.count
      
      stream_name = "Voting::Event$#{event.billetto_event_id}"
      initial_event_store_count = Rails.configuration.event_store.read.stream(stream_name).count

      post event_vote_path(event_id: event.billetto_event_id), params: { vote_type: "upvote" }

      expect(response).to have_http_status(:redirect)
      expect(response.location).to redirect_to(events_path)
      expect(Voting::Vote.count).to eq(initial_vote_count)
      expect(Rails.configuration.event_store.read.stream(stream_name).count).to eq(initial_event_store_count)
    end
  end

  describe "DELETE /events/:event_id/vote" do
    it "refuses unauthenticated users and prevents side effects" do
      initial_vote_count = Voting::Vote.count
      
      stream_name = "Voting::Event$#{event.billetto_event_id}"
      initial_event_store_count = Rails.configuration.event_store.read.stream(stream_name).count
      delete event_vote_path(event_id: event.billetto_event_id)

      expect(response).to have_http_status(:redirect)
      expect(response.location).to redirect_to(events_path)

      expect(Voting::Vote.count).to eq(initial_vote_count)
      expect(Rails.configuration.event_store.read.stream(stream_name).count).to eq(initial_event_store_count)
    end
  end
end
