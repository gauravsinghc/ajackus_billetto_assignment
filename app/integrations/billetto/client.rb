require "json"

module Billetto
  class Client
    BASE_URL = "https://billetto.dk/api/v3/"
    MAX_LIMIT = 100

    def initialize(api_keypair: ENV["BILLETTO_API_KEYPAIR"], connection: nil, open_timeout: 5, timeout: 10)
      if api_keypair.nil? || api_keypair.strip.empty?
        raise Errors::ConfigurationError, "BILLETTO_API_KEYPAIR must be configured"
      end

      @api_keypair = api_keypair
      @connection = connection || build_connection(open_timeout:, timeout:)
    end

    def public_events(limit: MAX_LIMIT)
      unless limit.is_a?(Integer) && limit.between?(1, MAX_LIMIT)
        raise Errors::InvalidRequestError, "limit must be an integer between 1 and #{MAX_LIMIT}"
      end

      response = @connection.get("public/events") do |request|
        request.params["limit"] = limit
        request.headers["Api-Keypair"] = @api_keypair
        request.headers["Accept"] = "application/json"
      end

      unless response.status.between?(200, 299)
        raise Errors::HttpError, response.status
      end

      payload = JSON.parse(response.body)
      unless payload.is_a?(Hash) && payload["data"].is_a?(Array)
        raise Errors::InvalidResponseError, "Billetto API response must contain a data array"
      end

      payload.fetch("data").map do |event_hash|
        Billetto::EventData.new(
          billetto_event_id: event_hash["id"].to_s,
          title:             event_hash["title"],
          description:       event_hash["description"],
          url:               event_hash["url"] || event_hash["public_url"],
          image_link:        event_hash["image_link"],
          state:             event_hash["state"],
          start_at:          event_hash["startdate"],
          end_at:            event_hash["enddate"],
          location:          event_hash["location"],
          minimum_price:     event_hash["minimum_price"],
          categorisation:    event_hash["categorisation"] || event_hash["categorization"],
          event_type:        event_hash["type"],
          localized_type:    event_hash["localized_type"]
        )
      end
    rescue JSON::ParserError, TypeError => error
      raise Errors::InvalidResponseError, "Billetto API returned invalid JSON", cause: error
    rescue Faraday::TimeoutError => error
      raise Errors::TimeoutError, "Billetto API request timed out", cause: error
    rescue Faraday::ConnectionFailed => error
      raise Errors::ConnectionError, "Billetto API connection failed", cause: error
    end

    private

    def build_connection(open_timeout:, timeout:)
      Faraday.new(url: BASE_URL) do |faraday|
        faraday.options.open_timeout = open_timeout
        faraday.options.timeout = timeout
      end
    end
  end
end