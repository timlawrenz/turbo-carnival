class AddPipelineRunToImageCandidates < ActiveRecord::Migration[8.0]
  def change
    add_reference :image_candidates, :pipeline_run, foreign_key: true, index: true
  end
end
