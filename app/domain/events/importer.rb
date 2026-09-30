module Events
  class Importer
    def initialize(events_data)
      @events_data = events_data
    end

    def call
      @events_data.each do |event_data|
        import_event(event_data)
      end
    end

    private

    def import_event(event_data)
      event = Event.find_or_initialize_by(billetto_event_id: event_data.billetto_event_id)

      event.assign_attributes(event_data.to_h.except(:billetto_event_id))

      if event.changed?
        event.last_seen_at = Time.current
        unless event.save
          Rails.logger.warn("Skipped invalid event #{event.billetto_event_id}: #{event.errors.full_messages.join(', ')}")
        end
      else
        event.update_column(:last_seen_at, Time.current) unless event.new_record?
      end
    rescue ArgumentError => e
      Rails.logger.warn("Failed to import event #{event_data.billetto_event_id}: #{e.message}")
    end
  end
end
