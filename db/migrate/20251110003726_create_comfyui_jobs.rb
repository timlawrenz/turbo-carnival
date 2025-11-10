class CreateComfyuiJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :comfyui_jobs do |t|
      t.references :image_candidate, foreign_key: true, index: true
      t.references :pipeline_run, null: false, foreign_key: true, index: true
      t.references :pipeline_step, null: false, foreign_key: true, index: true

      t.string :comfyui_job_id, index: true
      t.string :status, null: false, default: "pending", index: true
      t.jsonb :job_payload, null: false
      t.jsonb :result_metadata
      t.text :error_message
      t.integer :retry_count, default: 0, null: false

      t.datetime :submitted_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :comfyui_jobs, :job_payload, using: :gin
  end
end
