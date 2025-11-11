class AddWinnerStatusToImageCandidates < ActiveRecord::Migration[8.0]
  def change
    add_column :image_candidates, :winner, :boolean, default: false, null: false
    add_column :image_candidates, :winner_at, :datetime
    add_index :image_candidates, :winner
  end
end
