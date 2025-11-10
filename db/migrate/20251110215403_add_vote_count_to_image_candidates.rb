class AddVoteCountToImageCandidates < ActiveRecord::Migration[8.0]
  def change
    add_column :image_candidates, :vote_count, :integer, default: 0, null: false
    add_index :image_candidates, :vote_count
  end
end
