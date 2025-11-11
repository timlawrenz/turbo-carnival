class AddFailureCountToImageCandidates < ActiveRecord::Migration[8.0]
  def change
    add_column :image_candidates, :failure_count, :integer, default: 0, null: false
  end
end
