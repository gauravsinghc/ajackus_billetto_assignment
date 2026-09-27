module Billetto
  module Errors
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class InvalidRequestError < Error; end
    class InvalidResponseError < Error; end
    class TimeoutError < Error; end
    class ConnectionError < Error; end

    class HttpError < Error
      attr_reader :status

      def initialize(status)
        @status = status
        super("Billetto API returned HTTP #{status}")
      end
    end
  end
end