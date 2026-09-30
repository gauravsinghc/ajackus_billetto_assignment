class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pagy::Method
  include Clerk::Authenticatable
  helper_method :current_user

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def current_user
    # TEST MOCK: Allow system specs to simulate a logged-in user
    if Rails.env.test? && cookies[:test_user_id].present?
      return {
        id: cookies[:test_user_id],
        email: "test@example.com",
        name: "Capybara Tester"
      }
    end

    return nil unless clerk.user_id

    @current_user ||= {
      id: clerk.user_id,
      email: clerk.user&.email_addresses&.first&.email_address,
      name: clerk.user&.first_name || clerk.user&.email_addresses&.first&.email_address
    }
  end

end
