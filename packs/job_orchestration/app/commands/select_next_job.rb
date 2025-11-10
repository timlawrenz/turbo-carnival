class SelectNextJob < GLCommand::Callable
  returns :parent_candidate, :next_step, :mode

  def call
    eligible_parents = find_eligible_parents

    if eligible_parents.any?
      handle_child_generation(eligible_parents)
    else
      handle_no_eligible_parents
    end
  end

  private

  def find_eligible_parents
    max_children = JobOrchestrationConfig.max_children_per_node

    # Get IDs of final steps for each pipeline
    final_step_ids = Pipeline.includes(:pipeline_steps).map do |pipeline|
      pipeline.pipeline_steps.max_by(&:order)&.id
    end.compact

    ImageCandidate
      .includes(pipeline_step: :pipeline)
      .where(status: "active")
      .where("child_count < ?", max_children)
      .where.not(pipeline_step_id: final_step_ids)
  end

  def handle_child_generation(eligible_parents)
    # Group by pipeline step order and select highest
    parents_with_order = eligible_parents.to_a
    return if parents_with_order.empty?

    highest_order = parents_with_order.map { |p| p.pipeline_step.order }.max
    top_priority_candidates = parents_with_order.select { |p| p.pipeline_step.order == highest_order }

    # Perform ELO-weighted raffle
    selected_parent = weighted_raffle(top_priority_candidates)

    # Find next step
    next_step = selected_parent.pipeline_step.pipeline.pipeline_steps
      .where("\"order\" > ?", selected_parent.pipeline_step.order)
      .order(:order)
      .first

    context.parent_candidate = selected_parent
    context.next_step = next_step
    context.mode = :child_generation
  end

  def handle_no_eligible_parents
    # Check for deficit mode
    target = JobOrchestrationConfig.target_leaf_nodes

    # Find all pipelines and check their final steps
    pipelines = Pipeline.includes(:pipeline_steps).all

    pipelines.each do |pipeline|
      final_step = pipeline.pipeline_steps.last
      next unless final_step

      active_count = ImageCandidate.where(
        pipeline_step: final_step,
        status: "active"
      ).count

      if active_count < target
        # Check if we already have enough jobs in flight for the first step
        first_step = pipeline.pipeline_steps.first
        in_flight_count = ComfyuiJob.where(
          pipeline_step: first_step,
          status: %w[pending submitted running]
        ).count
        
        # Only trigger base generation if we don't have enough jobs in flight
        if in_flight_count < target
          context.parent_candidate = nil
          context.next_step = first_step
          context.mode = :base_generation
          return
        end
      end
    end

    # No deficit, no work
    context.parent_candidate = nil
    context.next_step = nil
    context.mode = :no_work
  end

  def weighted_raffle(candidates)
    candidates_array = candidates.to_a
    return candidates_array.first if candidates_array.size == 1

    total_weight = candidates_array.sum(&:elo_score)

    # Handle edge case of zero total weight
    if total_weight.zero?
      return candidates_array.sample
    end

    random_value = rand(0...total_weight)

    cumulative = 0
    candidates_array.each do |candidate|
      cumulative += candidate.elo_score
      return candidate if random_value < cumulative
    end

    candidates_array.last
  end
end
