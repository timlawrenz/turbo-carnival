class AddParentCandidateToComfyuiJobs < ActiveRecord::Migration[8.0]
  def change
    add_reference :comfyui_jobs, :parent_candidate, foreign_key: { to_table: :image_candidates }, index: true
  end
end
