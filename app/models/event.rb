class Event < ApplicationRecord
  enum :state, {
    canceled: 0,
    completed: 1,
    deleted: 2,
    draft: 3,
    published: 4,
    publishing: 5
  }

  validates :billetto_event_id, presence: true, uniqueness: true
  validates :title, presence: true
end
