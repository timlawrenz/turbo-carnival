# frozen_string_literal: true

module Personas
  class HashtagStrategy
    attr_reader :max_tags, :brand_tags, :strategy_type, :errors

    def initialize(attributes = {})
      @max_tags = attributes[:max_tags] || attributes['max_tags'] || 10
      @brand_tags = attributes[:brand_tags] || attributes['brand_tags'] || []
      @strategy_type = attributes[:strategy_type] || attributes['strategy_type']
      @errors = []
      validate
    end

    def valid?
      @errors.empty?
    end

    def to_hash
      {
        max_tags: @max_tags,
        brand_tags: @brand_tags,
        strategy_type: @strategy_type
      }.compact
    end

    def self.from_hash(hash)
      new(hash)
    end

    private

    def validate
      if @max_tags && (@max_tags < 1 || @max_tags > 30)
        @errors << "max_tags must be between 1 and 30"
      end
    end
  end
end
