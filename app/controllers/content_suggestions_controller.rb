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

  private

  def set_content_suggestion
    @content_suggestion = ContentSuggestion.find(params[:id])
  end
end
