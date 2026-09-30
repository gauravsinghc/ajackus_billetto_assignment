require 'rails_helper'

RSpec.describe "Authentication Flow", type: :system, js: true do
  it "verifies sign-up and login links point to the Clerk authentication UI" do
    visit root_path
    
    expect(page).to have_link("Login", href: /accounts\.dev/)
    expect(page).to have_link("Signup", href: /accounts\.dev/)
  end
  
  it "allows an authenticated user to logout through the UI" do
    visit root_path

    page.driver.browser.manage.add_cookie(name: 'test_user_id', value: 'system_test_user')
    
    visit root_path
    expect(page).to have_content("Welcome, Capybara Tester!")
    
    click_link "Logout"
    
    expect(page).not_to have_content("Welcome, Capybara Tester!")
    expect(page).to have_link("Login")
  end
end
