Clerk.configure do |config|
  config.secret_key = ENV.fetch("CLERK_SECRET_KEY")
end
