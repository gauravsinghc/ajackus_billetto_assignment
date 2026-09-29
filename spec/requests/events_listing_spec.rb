require 'rails_helper'

RSpec.describe "Events Listing (Phase 10)", type: :request do
  let(:clerk_mock) { double("Clerk", sign_in_url: "/sign-in", sign_up_url: "/sign-up", user_id: nil, user: nil) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:clerk).and_return(clerk_mock)
  end

  describe "GET /events" do
    let!(:event1) { Event.create!(billetto_event_id: "E1", title: "Event 1", start_at: 1.day.from_now) }
    let!(:event2) { Event.create!(billetto_event_id: "E2", title: "Event 2", start_at: 2.days.from_now) }

    context "when anonymous user" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
        
        # Seed vote counts (Read Model)
        EventVoteCount.create!(event_id: "E1", upvotes: 5, downvotes: 2) # Score: 3
        EventVoteCount.create!(event_id: "E2", upvotes: 1, downvotes: 4) # Score: -3
      end

      it "renders the events and their calculated scores" do
        get events_path
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Event 1")
        expect(response.body).to include("Event 2")
        
        # We expect the UI to display the scores
        expect(response.body).to include("3 Votes") # 5 - 2
        expect(response.body).to include("-3 Votes") # 1 - 4
      end

      it "links voting actions to the clerk sign-in URL" do
        get events_path
        
        # Anonymous users should see login links instead of real forms
        expect(response.body).to include('href="/sign-in"')
      end
    end

    context "when authenticated user" do
      let(:user_id) { "usr_123" }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return({ id: user_id, name: "Test User" })
        
        # Seed read model
        EventVoteCount.create!(event_id: "E1", upvotes: 1, downvotes: 0)
        EventVoteCount.create!(event_id: "E2", upvotes: 0, downvotes: 1)
        
        # Seed user's active write model votes
        Voting::Vote.create!(event_id: "E1", user_id: user_id, vote_type: "upvote")
        Voting::Vote.create!(event_id: "E2", user_id: user_id, vote_type: "downvote")
      end

      it "renders interactive voting forms pointing to the correct Billetto ID" do
        get events_path
        
        # Forms should target the business ID, not the Rails DB ID
        expect(response.body).to include('action="/events/E1/vote"')
        expect(response.body).to include('action="/events/E2/vote"')
      end

      it "identifies the user's active upvote" do
        get events_path
        
        # For E1, they have an upvote. We expect a highlighted/active state or a delete method.
        # Since we will implement `method: :delete` for the active vote:
        expect(response.body).to include('name="_method" value="delete"')
      end
    end

    context "N+1 prevention" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return({ id: "usr_123", name: "Test User" })
      end

      it "fetches vote counts and user votes in bulk (exactly 1 query each)" do
        # We assert that the class receives `where` with `event_id: array_of_ids` exactly once
        expect(EventVoteCount).to receive(:where).with(hash_including(:event_id)).once.and_call_original
        expect(Voting::Vote).to receive(:where).with(hash_including(:event_id, :user_id)).once.and_call_original
        
        get events_path
      end
    end
  end
end
