class CreatePipelineSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :pipeline_steps do |t|
      t.references :pipeline, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :order, null: false
      t.text :comfy_workflow_json, null: false

      t.timestamps
    end

    add_index :pipeline_steps, [ :pipeline_id, :order ], unique: true
  end
end
