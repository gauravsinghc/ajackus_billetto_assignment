require 'stoplight'

Stoplight.configure do |config|
  if Rails.env.test?
    config.data_store = Stoplight::DataStore::Memory.new
  else
    redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/1'))
    config.data_store = Stoplight::DataStore::Redis.new(redis)
  end
end
