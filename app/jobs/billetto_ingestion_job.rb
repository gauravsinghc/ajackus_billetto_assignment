# Since we don't have pagination for this API, we fetch 100 records at once.
# Therefore, we don't need to implement rate-limiting hitting inside this job.
class BillettoIngestionJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform
    light = Stoplight('billetto-api', threshold: 3, cool_off_time: 60)
    begin
      events_data = light.run do
        Billetto::Client.new.public_events
      end
      Events::Importer.new(events_data).call
    rescue Stoplight::Error::RedLight
      raise "Billetto API Circuit Breaker is OPEN. Job will be retried later."
    rescue Billetto::Errors::HttpError, Billetto::Errors::TimeoutError, Billetto::Errors::InvalidResponseError => e
      raise e
    end
  end
end
