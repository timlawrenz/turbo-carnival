class ContentSuggestionsController < ApplicationController
  before_action :set_content_suggestion

  def use
    @content_suggestion.mark_as_used!
    redirect_back fallback_location: root_path, notice: "Suggestion marked as used"
  end

  def reject
    @content_suggestion.mark_as_rejected!
    redirect_back fallback_location: root_path, notice: "Suggestion rejected"
  end

  def create_cluster
    cluster = Clustering::Cluster.create!(
      persona: @content_suggestion.gap_analysis.persona,
      content_pillar: @content_suggestion.content_pillar,
      name: @content_suggestion.title,
      description: @content_suggestion.description
    )

    @content_suggestion.update!(cluster: cluster)
    @content_suggestion.mark_as_used!

    redirect_to persona_pillar_cluster_path(
      cluster.persona,
      cluster.content_pillar,
      cluster
    ), notice: "New cluster created from suggestion!"
  end

  def generate_image
    # Get the cluster - either existing from prompt_data or create new one
    cluster_id = @content_suggestion.prompt_data['cluster_id']
    
    unless cluster_id
      # Create cluster if it doesn't exist
      cluster = Clustering::Cluster.create!(
        persona: @content_suggestion.gap_analysis.persona,
        content_pillar: @content_suggestion.content_pillar,
        name: @content_suggestion.title,
        description: @content_suggestion.description
      )
      @content_suggestion.update!(cluster: cluster)
      cluster_id = cluster.id
    end

    # Use the existing sarah1a3 pipeline
    pipeline = Pipeline.first || Pipeline.find_by(name: 'sarah1a3')
    
    unless pipeline
      redirect_back fallback_location: root_path, 
                    alert: "No pipeline configured. Please set up a pipeline first."
      return
    end

    # Create pipeline run
    run = PipelineRun.create!(
      pipeline: pipeline,
      persona: @content_suggestion.gap_analysis.persona,
      cluster_id: cluster_id,
      prompt: @content_suggestion.prompt_data['prompt'],
      name: "Gap Analysis: #{@content_suggestion.title}",
      target_folder: "gap_analysis/#{@content_suggestion.id}",
      status: 'pending'
    )

    redirect_to run_path(run), 
                notice: "Image generation started! Pipeline will generate candidates for '#{@content_suggestion.title}'"
  end

  private

  def set_content_suggestion
    @content_suggestion = ContentSuggestion.find(params[:id])
  end
end
