module EventStoreInjector
  extend ActiveSupport::Concern

  class RoutingEventStore
    def initialize(client)
      @client = client
    end

    def publish(event, **kwargs)
      if event.respond_to?(:stream_names) && event.stream_names.any? && !kwargs.key?(:stream_name) && !kwargs.key?(:stream_names)
        main_stream = event.stream_names.first
        linked_streams = event.stream_names.drop(1)
        
        @client.publish(event, stream_name: main_stream, **kwargs)
        
        linked_streams.each do |stream|
          @client.link(event.event_id, stream_name: stream)
        end
      else
        @client.publish(event, **kwargs)
      end
    end

    def method_missing(method, *args, &block)
      if @client.respond_to?(method)
        @client.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      @client.respond_to?(method, include_private) || super
    end
  end

  def event_store
    @routing_event_store ||= RoutingEventStore.new(Rails.configuration.event_store)
  end
end