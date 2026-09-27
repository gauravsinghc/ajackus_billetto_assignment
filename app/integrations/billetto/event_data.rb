module Billetto
  EventData = Data.define(
    :billetto_event_id,
    :title,
    :description,
    :url,
    :image_link,
    :state,
    :start_at,
    :end_at,
    :location,
    :minimum_price,
    :categorisation,
    :event_type,
    :localized_type
  )
end
