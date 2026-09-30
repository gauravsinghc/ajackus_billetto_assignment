require 'rails_helper'

RSpec.describe "Voting Flow", type: :system, js: true do
  let!(:event) do
    Event.create!(
      billetto_event_id: "test-event-123",
      title: "Test Event",
      event_type: "party",
      location: {},
      start_at: 1.day.from_now,
      minimum_price: {},
      image_link: "http://example.com/image.jpg",
      state: "published",
      last_seen_at: Time.current
    )
  end

  before do
    EventVoteCount.delete_all
    Voting::Vote.delete_all
  end

  it "allows an authenticated user to cast, change, and remove a vote" do
    visit root_path

    page.driver.browser.manage.add_cookie(name: 'test_user_id', value: 'system_test_user')

    visit root_path

    expect(page).to have_content("Welcome, Capybara Tester!")
    
    expect(page).to have_content("0 Votes")
    
    click_button "Upvote"
    
    expect(page).to have_content("1 Votes")
    expect(page).to have_button("Upvoted")
    
    click_button "Downvote"
    
    expect(page).to have_content("-1 Votes")
    expect(page).to have_button("Downvoted")
    
    click_button "Downvoted"
    
    expect(page).to have_content("0 Votes")
    expect(page).to have_button("Upvote")
  end
end
