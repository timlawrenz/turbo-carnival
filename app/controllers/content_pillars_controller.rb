class ContentPillarsController < ApplicationController
  def show
    @persona = Persona.find(params[:persona_id])
    @pillar = @persona.content_pillars.find(params[:id])
    @clusters = @pillar.clusters.includes(:photos, :pipeline_runs).order(created_at: :desc)
  end
end
