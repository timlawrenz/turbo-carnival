class CreatePipelineRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :pipeline_runs do |t|
      t.references :pipeline, null: false, foreign_key: true
      t.string :name
      t.string :target_folder
      t.jsonb :variables, null: false, default: {}
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :pipeline_runs, :status
    add_index :pipeline_runs, :variables, using: :gin
  end
end
