class AddUniqueIndexToVotingVotes < ActiveRecord::Migration[8.1]
  def change
    add_index :voting_votes, [:event_id, :user_id], unique: true
  end
end
