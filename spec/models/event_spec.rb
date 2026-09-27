require 'rails_helper'

RSpec.describe Event, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      event = Event.new(
        billetto_event_id: "2020957",
        title: "Cohen i kirken",
        description: "Kom til koncertfortællingen...",
        url: "https://billetto.dk/e/cohen-i-kirken-billetter-2020957",
        state: "published",
        event_type: "seminar",
        localized_type: "Seminar eller Foredrag",
        minimum_price: { "amount" => "0.0", "currency" => "DKK" },
        categorisation: { "category" => "business" }
      )
      expect(event).to be_valid
    end

    it "is invalid without a billetto_event_id" do
      event = Event.new(title: "Cohen i kirken")
      expect(event).not_to be_valid
      expect(event.errors[:billetto_event_id]).to include("can't be blank")
    end

    it "is invalid without a title" do
      event = Event.new(billetto_event_id: "2020957")
      expect(event).not_to be_valid
      expect(event.errors[:title]).to include("can't be blank")
    end

    it "enforces uniqueness of billetto_event_id" do
      Event.create!(billetto_event_id: "2020957", title: "Original Event")
      duplicate_event = Event.new(billetto_event_id: "2020957", title: "Duplicate Event")
      
      expect(duplicate_event).not_to be_valid
      expect(duplicate_event.errors[:billetto_event_id]).to include("has already been taken")
    end
  end
end
