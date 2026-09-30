require 'rails_helper'

RSpec.describe "Browser Test Infrastructure", type: :system do
  it "boots the browser and verifies the UI renders" do
    visit root_path
    expect(page).to have_content("Billetto Events")
  end

  it "can mock the Clerk authentication deterministicly", js: true do
    visit root_path

    page.driver.browser.manage.add_cookie(name: 'test_user_id', value: 'user_test_123')
    
    visit root_path
    expect(page).to have_content("Welcome, Capybara Tester!")
  end
end
