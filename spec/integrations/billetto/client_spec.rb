require "rails_helper"

RSpec.describe Billetto::Client do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection) do
    Faraday.new(url: described_class::BASE_URL) do |faraday|
      faraday.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(api_keypair: "test-keypair", connection:) }

  after do
    stubs.verify_stubbed_calls
  end

  describe "#public_events" do
    it "sends the API keypair and bounded limit, then returns the data array" do
      events = [{ "id" => "event-123", "title" => "A test event" }]

      stubs.get("/api/v3/public/events?limit=100") do |request|
        expect(request.request_headers["Api-Keypair"]).to eq("test-keypair")
        expect(request.request_headers["Accept"]).to eq("application/json")
        [200, { "Content-Type" => "application/json" }, JSON.generate("data" => events)]
      end

      expect(client.public_events).to eq(events)
    end

    it "allows a caller to request a smaller bounded result" do
      stubs.get("/api/v3/public/events?limit=25") do
        [200, { "Content-Type" => "application/json" }, JSON.generate("data" => [])]
      end

      expect(client.public_events(limit: 25)).to eq([])
    end

    it "rejects limits outside the documented range" do
      expect { client.public_events(limit: 101) }
        .to raise_error(Billetto::Errors::InvalidRequestError)
    end

    it "raises an HTTP error for unsuccessful responses" do
      stubs.get("/api/v3/public/events?limit=100") do
        [503, { "Content-Type" => "application/json" }, "{}"]
      end

      expect { client.public_events }.to raise_error(Billetto::Errors::HttpError) { |error|
        expect(error.status).to eq(503)
      }
    end

    it "rejects malformed JSON" do
      stubs.get("/api/v3/public/events?limit=100") do
        [200, { "Content-Type" => "application/json" }, "{"]
      end

      expect { client.public_events }.to raise_error(Billetto::Errors::InvalidResponseError)
    end

    it "rejects responses without a data array" do
      stubs.get("/api/v3/public/events?limit=100") do
        [200, { "Content-Type" => "application/json" }, JSON.generate("data" => {})]
      end

      expect { client.public_events }.to raise_error(Billetto::Errors::InvalidResponseError)
    end

    it "raises a configuration error when the keypair is missing" do
      expect { described_class.new(api_keypair: nil, connection:) }
        .to raise_error(Billetto::Errors::ConfigurationError)
    end

    it "converts request timeouts to a client error" do
      stubs.get("/api/v3/public/events?limit=100") do
        raise Faraday::TimeoutError, "request timed out"
      end

      expect { client.public_events }.to raise_error(Billetto::Errors::TimeoutError)
    end
  end
end