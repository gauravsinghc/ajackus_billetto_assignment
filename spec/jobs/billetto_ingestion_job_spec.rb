require 'rails_helper'

RSpec.describe BillettoIngestionJob, type: :job do
  describe '#perform' do
    let(:client_double) { instance_double(Billetto::Client) }
    let(:importer_double) { instance_double(Events::Importer) }
    let(:events_data) { [instance_double(Billetto::EventData)] }

    before do
      allow(Billetto::Client).to receive(:new).and_return(client_double)
      
      # Reset Stoplight's memory state before each test
      Stoplight.configure do |config|
        config.data_store = Stoplight::DataStore::Memory.new
      end
    end

    it 'fetches events and passes them to the importer successfully' do
      expect(client_double).to receive(:public_events).and_return(events_data)
      expect(Events::Importer).to receive(:new).with(events_data).and_return(importer_double)
      expect(importer_double).to receive(:call)

      described_class.new.perform
    end

    it 'triggers the circuit breaker after 3 repeated failures' do
      allow(client_double).to receive(:public_events).and_raise(Billetto::Errors::TimeoutError.new("timeout"))

      # Fail 3 times (the threshold)
      3.times do
        expect { described_class.new.perform }.to raise_error(Billetto::Errors::TimeoutError)
      end

      # On the 4th time, it should raise a RedLight error because the circuit is OPEN.
      # The client should NOT receive :public_events because the network call is blocked!
      expect(client_double).not_to receive(:public_events)
      
      expect { described_class.new.perform }.to raise_error(RuntimeError, /Circuit Breaker is OPEN/)
    end
  end
end
