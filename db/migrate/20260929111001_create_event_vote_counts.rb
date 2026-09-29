class CreateEventVoteCounts < ActiveRecord::Migration[8.1]
  def change
    create_table :event_vote_counts, id: false do |t|
      t.string :event_id, primary_key: true
      t.integer :upvotes, default: 0, null: false
      t.integer :downvotes, default: 0, null: false

      t.timestamps null: false
    end
  end
end
