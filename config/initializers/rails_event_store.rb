Rails.configuration.to_prepare do
  event_store = RailsEventStore::JSONClient.new
  
  if defined?(Voting) && Voting.respond_to?(:subscriptions)
    Voting.subscriptions.each do |subscriber, events|
      event_store.subscribe(subscriber, to: events)
    end
  end

  Rails.configuration.event_store = event_store
end
