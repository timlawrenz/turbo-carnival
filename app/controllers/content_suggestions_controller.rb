class ContentSuggestionsController < ApplicationController
  before_action :set_persona, only: [:index]
  before_action :set_content_suggestion, except: [:index]

  def index
    @content_suggestions = ContentSuggestion
      .joins(:gap_analysis)
      .where(gap_analyses: { persona_id: @persona.id })
      .includes(:content_pillar, :gap_analysis)
      .order(created_at: :desc)
  end

  def use
    @content_suggestion.mark_as_used!
    redirect_back fallback_location: root_path, notice: "Suggestion marked as used"
  end

  def reject
    @content_suggestion.mark_as_rejected!
    redirect_back fallback_location: root_path, notice: "Suggestion rejected"
  end

  def generate_image
    # Use the existing sarah1a3 pipeline
    pipeline = Pipeline.first || Pipeline.find_by(name: 'sarah1a3')
    
    unless pipeline
      redirect_back fallback_location: root_path, 
                    alert: "No pipeline configured. Please set up a pipeline first."
      return
    end

    # Create pipeline run directly for the pillar
    run = PipelineRun.create!(
      pipeline: pipeline,
      persona: @content_suggestion.gap_analysis.persona,
      content_pillar_id: @content_suggestion.content_pillar_id,
      prompt: @content_suggestion.prompt_data['prompt'],
      name: "Gap Analysis: #{@content_suggestion.title}",
      target_folder: "gap_analysis/#{@content_suggestion.id}",
      status: 'pending'
    )

    @content_suggestion.mark_as_used!

    redirect_to run_path(run), 
                notice: "Image generation started! Pipeline will generate candidates for '#{@content_suggestion.title}'"
  end

  private

  def set_persona
    @persona = Persona.find(params[:persona_id])
  end

  def set_content_suggestion
    @content_suggestion = ContentSuggestion.find(params[:id])
  end
end
