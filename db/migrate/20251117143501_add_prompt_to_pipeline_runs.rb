class AddPromptToPipelineRuns < ActiveRecord::Migration[8.0]
  def change
    add_column :pipeline_runs, :prompt, :string
  end
end
