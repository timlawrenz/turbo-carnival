# frozen_string_literal: true

module ContentStrategy
  class Context
    attr_reader :persona, :pillar, :clusters, :history, :state, :config

    def initialize(persona:, pillar: nil)
      @persona = persona
      @pillar = pillar
      @config = ConfigLoader
      load_context
    end

    def selected_pillar
      @pillar
    end

    private

    def load_context
      @clusters = load_clusters
      @history = load_history
      @state = load_state
    end

    def load_clusters
      base_scope = Clustering::Cluster.for_persona(@persona.id)
      
      # Filter by pillar if provided
      base_scope = base_scope.for_pillar(@pillar) if @pillar

      # Only clusters with unposted photos
      base_scope
        .joins(:photos)
        .where.not(id: Scheduling::Post.select(:cluster_id).where.not(cluster_id: nil))
        .distinct
        .order(:name)
    end

    def load_history
      HistoryRecord
        .for_persona(@persona.id)
        .recent_days(30)
        .includes(:cluster, :post)
        .recent
    end

    def load_state
      StrategyState.find_or_create_by!(persona: @persona) do |state|
        state.active_strategy = @config.default_strategy
        state.started_at = Time.current
      end
    end
  end
end
