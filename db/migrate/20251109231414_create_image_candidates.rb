class CreateImageCandidates < ActiveRecord::Migration[8.0]
  def change
    create_table :image_candidates do |t|
      t.references :pipeline_step, null: false, foreign_key: true
      t.bigint :parent_id
      t.string :image_path
      t.integer :elo_score, null: false, default: 1000
      t.string :status, null: false, default: "active"
      t.integer :child_count, null: false, default: 0

      t.timestamps
    end

    add_index :image_candidates, :parent_id
    add_index :image_candidates, [ :status, :child_count ]
    add_index :image_candidates, :elo_score
    add_foreign_key :image_candidates, :image_candidates, column: :parent_id
  end
end
