# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    mock_clerk_middleware
  end
  
  config.before(:each, type: :request) do
    mock_clerk_middleware
  end
  
  def mock_clerk_middleware
    # A lightweight dummy object to simulate Clerk's request.env['clerk'] proxy
    # without making actual HTTP requests to Clerk's servers during CI.
    dummy_clerk = Object.new
    def dummy_clerk.user_id; nil; end
    def dummy_clerk.session; nil; end
    def dummy_clerk.user; nil; end
    def dummy_clerk.sign_in_url; "https://dummy.clerk.accounts.dev/sign-in"; end
    def dummy_clerk.sign_up_url; "https://dummy.clerk.accounts.dev/sign-up"; end

    allow_any_instance_of(Clerk::Rack::Middleware).to receive(:call) do |instance, env|
      env["clerk"] = dummy_clerk
      instance.instance_variable_get(:@app).call(env)
    end
  end
end
