require 'sidekiq/cron'
redis_url = ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0")

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

if Sidekiq.server?
  Sidekiq::Cron::Job.create(
    name: 'Billetto Ingestion - Every night at midnight',
    cron: '0 0 * * *', # Standard cron syntax for "00:00" (midnight)
    class: 'BillettoIngestionJob'
  )
end