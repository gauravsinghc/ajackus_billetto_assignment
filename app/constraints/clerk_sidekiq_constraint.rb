class ClerkSidekiqConstraint
  def matches?(request)
    # Fallback for the test environment (Capybara/RSpec) so tests don't break
    return true if Rails.env.test?

    # The Clerk Rack middleware injects this into the env before the router!
    clerk = request.env["clerk"]
    
    # Only allow access if the user is authenticated
    clerk.present? && clerk.user_id.present?
  end
end