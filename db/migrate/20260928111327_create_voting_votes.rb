class CreateVotingVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :voting_votes do |t|
      t.string :event_id
      t.string :user_id
      t.string :vote_type

      t.timestamps
    end
  end
end
