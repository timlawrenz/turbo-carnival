# frozen_string_literal: true

module CaptionGeneration
  class ContextBuilder
    def self.build(photo:, cluster: nil)
      new(photo: photo, cluster: cluster).build
    end

    def initialize(photo:, cluster: nil)
      @photo = photo
      @cluster = cluster
    end

    def build
      {
        cluster_name: cluster_name,
        cluster_data: cluster_data,
        persona_name: @photo.persona&.name
      }
    end

    private

    def cluster_name
      @cluster&.name || @photo.cluster&.name
    end

    def cluster_data
      cluster = @cluster || @photo.cluster
      return nil unless cluster

      {
        name: cluster.name,
        ai_prompt: cluster.ai_prompt
      }.compact
    end
  end
end
