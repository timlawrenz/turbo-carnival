# frozen_string_literal: true

module Growth
  # Mutates a persona's identity knobs in a bounded, reversible way, always
  # recording a before/after change record so the autonomous experiment can be
  # audited and rolled back. Every decision is conservative: single-step
  # deltas within hard caps, never wholesale resets.
  #
  # Mutatable knobs:
  #   - ContentPillar: weight / priority / active (shift share toward what works)
  #   - Persona.caption_config: tone/style/voice
  #   - Persona.hashtag_strategy: max_tags / brand_tags
  class PersonaEvolution
    WEIGHT_STEP    = 10
    WEIGHT_MIN     = 5
    PRIORITY_MIN   = 1
    PRIORITY_STEP  = 1
    TAG_STEP       = 5
    TAG_MIN        = 3
    TAG_MAX        = 30

    attr_reader :goal, :changes

    def initialize(goal:)
      @goal = goal
      @changes = []
    end

    def persona
      goal.persona
    end

    # Shift weight/priority from under-performing pillars to over-performing
    # ones. pillars is [{name:, posts:, engagement:}] ordered strongest first.
    def reweight_toward_top(pillars)
      return [] if pillars.size < 2

      top, *rest = pillars
      bottom = rest.last
      # Only shift if there's a meaningful observed gap and enough throughput
      return [] if top[:posts] < 3 || bottom[:posts] < 3
      return [] if (top[:engagement] - bottom[:engagement]).abs < 0.5

      top_pillar   = find_pillar(top[:name])
      bottom_pillar = find_pillar(bottom[:name])
      return [] unless top_pillar && bottom_pillar

      reward(top_pillar, WEIGHT_STEP, bottom_pillar)
      changes.last(2)
    end

    # Adjust caption tone/style based on what's engaging. action: :warmer/:bolder/:calmer/:balanced
    def adjust_caption(action)
      config = persona.caption_config
      return [] unless config

      tone   = config.tone || 'friendly'
      style  = config.style || 'casual'
      case action
      when :warmer
        tone = 'warm' if tone == 'friendly'
        style = 'intimate' unless style.include?('intimate')
      when :bolder
        tone  = 'confident'
        style = 'bold'
      when :calmer
        tone  = 'calm'
        style = 'minimal'
      when :balanced
        tone  = 'warm'
        style = 'authentic'
      end

      from = { tone: config.tone, style: config.style }
      persona.caption_config = Personas::CaptionConfig.new(config.to_hash.merge(tone: tone, style: style))
      persona.save!
      record(:caption_config, from, { tone: tone, style: style }, "caption action=#{action}")
      changes.last
    end

    # Adjust hashtag volume/count within bounds.
    def adjust_hashtags(posts:, engagement:)
      strategy = persona.hashtag_strategy || Personas::HashtagStrategy.new
      if posts >= 5 && engagement > 5.0
        from = strategy.to_hash
        reduce_tags(strategy)
        record(:hashtag_strategy, from, persona.hashtag_strategy.to_hash, 'high engagement — tighten tags')
      elsif posts >= 5 && engagement < 1.0
        from = strategy.to_hash
        expand_tags(strategy)
        record(:hashtag_strategy, from, persona.hashtag_strategy.to_hash, 'low engagement — broaden tags')
      end
      changes.last
    end

    private

    def find_pillar(name)
      persona.content_pillars.current.find { |p| p.name.casecmp?(name) }
    end

    def reward(pillar, step, penalty_pillar)
      from = { id: pillar.id, weight: pillar.weight, priority: pillar.priority }
      p_from = { id: penalty_pillar.id, weight: penalty_pillar.weight, priority: penalty_pillar.priority }

      # Compute both new weights FIRST so the total never transiently exceeds
      # 100% (the ContentPillar validation would otherwise reject the reward
      # before the penalty brings the sum back down).
      new_bottom_weight = [penalty_pillar.weight - step, WEIGHT_MIN].max
      transfer = penalty_pillar.weight - new_bottom_weight   # actual share freed
      new_top_weight    = [pillar.weight + transfer, 100].min

      new_top_priority    = [pillar.priority + PRIORITY_STEP, 5].min
      new_bottom_priority = [penalty_pillar.priority - PRIORITY_STEP, PRIORITY_MIN].max

      ContentPillar.transaction do
        penalty_pillar.update!(weight: new_bottom_weight, priority: new_bottom_priority)
        pillar.update!(weight: new_top_weight, priority: new_top_priority, active: true)
      end

      record(:content_pillar, from, { id: pillar.id, weight: pillar.weight, priority: pillar.priority }, "reward #{pillar.name}")
      record(:content_pillar, p_from, { id: penalty_pillar.id, weight: penalty_pillar.weight, priority: penalty_pillar.priority }, "penalize #{penalty_pillar.name}")
    end

    def reduce_tags(strategy)
      max = strategy.max_tags.to_i
      brand = Array(strategy.brand_tags || [])
      persona.hashtag_strategy = Personas::HashtagStrategy.new(
        strategy.to_hash.merge(max_tags: [[max - TAG_STEP, TAG_MIN].max, 1].max)
      )
      persona.save!
    end

    def expand_tags(strategy)
      max = strategy.max_tags.to_i
      persona.hashtag_strategy = Personas::HashtagStrategy.new(
        strategy.to_hash.merge(max_tags: [[max + TAG_STEP, TAG_MAX].min, 1].max)
      )
      persona.save!
    end

    def record(kind, from, to, reason)
      @changes << { kind: kind, from: from, to: to, reason: reason, at: Time.current }
    end
  end
end