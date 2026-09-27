class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :billetto_event_id
      t.string :title
      t.text :description
      t.string :url
      t.string :image_link
      t.integer :state
      t.datetime :start_at
      t.datetime :end_at
      t.jsonb :location
      t.jsonb :minimum_price
      t.jsonb :categorisation
      t.string :event_type
      t.string :localized_type
      t.datetime :last_seen_at

      t.timestamps
    end
    add_index :events, :billetto_event_id, unique: true
  end
end
