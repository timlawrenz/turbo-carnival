class ContentPillarsController < ApplicationController
  def show
    @persona = Persona.find(params[:persona_id])
    @pillar = @persona.content_pillars.find(params[:id])
    @content_pillar = @pillar # Alias for view compatibility
    @photos = @pillar.photos.includes(:image_candidate).order(created_at: :desc)
  end

  def suggest
    @persona = Persona.find(params[:persona_id])
    @pillar = @persona.content_pillars.find(params[:id])
    
    existing_photos = @pillar.photos
    
    @suggestions = GapAnalysis::AiSuggester.suggest(
      pillar: @pillar,
      persona: @persona,
      existing_photos: existing_photos
    )
    
    render :suggest
  rescue StandardError => e
    redirect_to persona_pillar_path(@persona, @pillar), alert: "Error generating suggestions: #{e.message}"
  end
end
