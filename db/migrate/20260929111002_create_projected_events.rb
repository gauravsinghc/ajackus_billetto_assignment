class CreateProjectedEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :projected_events, id: false do |t|
      t.uuid :event_uuid, primary_key: true, null: false
      t.datetime :created_at, null: false
    end
  end
end
