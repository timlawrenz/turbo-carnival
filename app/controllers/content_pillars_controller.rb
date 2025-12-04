class ContentPillarsController < ApplicationController
  def show
    @persona = Persona.find(params[:persona_id])
    @pillar = @persona.content_pillars.find(params[:id])
    @clusters = @pillar.clusters.includes(:photos, :pipeline_runs).order(created_at: :desc)
  end

  def suggest
    @persona = Persona.find(params[:persona_id])
    @pillar = @persona.content_pillars.find(params[:id])
    
    existing_clusters = @pillar.clusters
    existing_photos = @persona.photos.includes(:cluster).where(cluster: { content_pillar_id: @pillar.id })
    
    @suggestions = GapAnalysis::AiSuggester.suggest(
      pillar: @pillar,
      persona: @persona,
      existing_clusters: existing_clusters,
      existing_photos: existing_photos
    )
    
    render :suggest
  rescue StandardError => e
    redirect_to persona_content_pillar_path(@persona, @pillar), alert: "Error generating suggestions: #{e.message}"
  end
end
