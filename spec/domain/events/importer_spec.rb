require 'rails_helper'
require_relative '../../../app/integrations/billetto/event_data' # ensure struct is loaded for tests

RSpec.describe Events::Importer do
  let(:valid_event_data) do
    Billetto::EventData.new(
      billetto_event_id: "1001",
      title: "My Awesome Concert",
      description: "It will be great.",
      url: "https://billetto.dk/e/1001",
      image_link: nil,
      state: "published",
      start_at: "2027-01-31T15:00:00Z",
      end_at: nil,
      location: nil,
      minimum_price: nil,
      categorisation: nil,
      event_type: nil,
      localized_type: nil
    )
  end

  describe "#call" do
    it "creates a new event on first import" do
      importer = described_class.new([valid_event_data])
      
      expect { importer.call }.to change(Event, :count).by(1)
      
      event = Event.last
      expect(event.billetto_event_id).to eq("1001")
      expect(event.title).to eq("My Awesome Concert")
      expect(event.state).to eq("published")
      expect(event.last_seen_at).to be_present
    end

    it "updates an existing event if attributes changed" do
      Event.create!(
        billetto_event_id: "1001", 
        title: "Old Title", 
        state: "draft"
      )

      importer = described_class.new([valid_event_data])
      expect { importer.call }.not_to change(Event, :count)

      event = Event.find_by(billetto_event_id: "1001")
      expect(event.title).to eq("My Awesome Concert")
      expect(event.state).to eq("published")
    end

    it "performs a no-op update efficiently if attributes are identical" do
      event = Event.create!(
        billetto_event_id: "1001", 
        title: "My Awesome Concert", 
        state: "published",
        description: "It will be great.",
        url: "https://billetto.dk/e/1001",
        start_at: "2027-01-31T15:00:00Z"
      )
      
      expect_any_instance_of(Event).to receive(:update_column).with(:last_seen_at, anything)
      expect_any_instance_of(Event).not_to receive(:save)

      importer = described_class.new([valid_event_data])
      importer.call
    end

    it "skips invalid events without losing the batch" do
      invalid_data = valid_event_data.with(title: nil)
      valid_data_2 = valid_event_data.with(billetto_event_id: "1002")

      importer = described_class.new([invalid_data, valid_data_2])
      
      expect { importer.call }.to change(Event, :count).by(1)
      expect(Event.exists?(billetto_event_id: "1002")).to be true
      expect(Event.exists?(billetto_event_id: "1001")).to be false
    end

    it "skips events with an unknown state enum without losing the batch" do
      invalid_state_data = valid_event_data.with(state: "some_weird_new_state")
      valid_data_2 = valid_event_data.with(billetto_event_id: "1002")

      importer = described_class.new([invalid_state_data, valid_data_2])
      
      expect { importer.call }.to change(Event, :count).by(1)
      expect(Event.exists?(billetto_event_id: "1002")).to be true
    end
  end
end
