class AddVariableFlagsToPipelineSteps < ActiveRecord::Migration[8.0]
  def change
    add_column :pipeline_steps, :needs_run_prompt, :boolean, default: false, null: false
    add_column :pipeline_steps, :needs_parent_image_path, :boolean, default: false, null: false
    add_column :pipeline_steps, :needs_run_variables, :boolean, default: false, null: false
  end
end
