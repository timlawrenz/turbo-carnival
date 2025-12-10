# frozen_string_literal: true

module ContentStrategy
  class NoAvailableClustersError < StandardError
    def initialize(persona_id)
      @persona_id = persona_id
      super("No available clusters for persona #{@persona_id}")
    end
  end
end
