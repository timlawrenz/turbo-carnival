class ContentPillarsController < ApplicationController
  def show
    @persona = Persona.find(params[:persona_id])
    @pillar = @persona.content_pillars.find(params[:id])
    @content_pillar = @pillar # Alias for view compatibility
    @clusters = Clustering::Cluster.for_pillar(@pillar).includes(:photos, :pipeline_runs).order(created_at: :desc)
  end

  def suggest
    @persona = Persona.find(params[:persona_id])
    @pillar = @persona.content_pillars.find(params[:id])
    
    existing_clusters = @pillar.clusters
    # Get photos from clusters associated with this pillar
    existing_photos = Clustering::Photo.joins(cluster: :pillar_cluster_assignments)
                                       .where(pillar_cluster_assignments: { pillar_id: @pillar.id })
                                       .where(clusters: { persona_id: @persona.id })
    
    @suggestions = GapAnalysis::AiSuggester.suggest(
      pillar: @pillar,
      persona: @persona,
      existing_clusters: existing_clusters,
      existing_photos: existing_photos
    )
    
    render :suggest
  rescue StandardError => e
    redirect_to persona_pillar_path(@persona, @pillar), alert: "Error generating suggestions: #{e.message}"
  end
end
