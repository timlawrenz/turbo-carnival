## Context
This change implements the core job selection algorithm that decides which ComfyUI job to run next. The algorithm prioritizes finishing work (right-to-left through pipeline steps), uses ELO-weighted probabilistic selection for exploration/exploitation balance, and autonomously generates new base images when needed.

## Goals
- Implement deterministic, state-based job selection
- Prioritize finishing work over starting new branches
- Balance exploitation (best candidates) with exploration (give others a chance)
- Autonomous operation (generate base images when needed)
- Clear separation of concerns using GLCommand pattern

## Non-Goals
- ComfyUI API integration (separate concern)
- Job execution/worker management (separate concern)
- Result processing/image storage (separate concern)

## Decisions

### Use GLCommand Pattern
**Decision**: Implement job selection and payload construction as GLCommands.

**Rationale**:
- Aligns with project conventions
- Commands are testable in isolation
- Rollback support if needed
- Can be chained for complex workflows

### Separate SelectNextJob and BuildJobPayload
**Decision**: Two commands instead of one monolithic operation.

**Rationale**:
- Single responsibility principle
- SelectNextJob focuses on algorithm
- BuildJobPayload focuses on variable substitution
- Easier to test independently

**Alternatives considered**:
- Single command - Rejected: too much responsibility
- Service object - Rejected: project uses GLCommand pattern

### Configuration Class
**Decision**: Create `JobOrchestrationConfig` class for N and T parameters.

**Rationale**:
- Centralized configuration
- Easy to change without code modification
- Can be environment-specific later
- Testable

**Initial values**:
- N (max children) = 5
- T (target leaf nodes) = 10

## Algorithm Design

### SelectNextJob Command

**Inputs**: None (reads from database)

**Outputs**: 
- `parent_candidate` (ImageCandidate or nil)
- `next_step` (PipelineStep or nil)
- `mode` (:child_generation or :base_generation or :no_work)

**Algorithm**:

```ruby
1. Find Eligible Parents
   Query ImageCandidates where:
   - status = 'active'
   - child_count < N
   - pipeline_step.order < max_order_for_pipeline
   
2. If eligible parents found:
   a. Group by pipeline_step.order
   b. Select highest order group (right-most)
   c. Perform ELO raffle within group:
      - Calculate total ELO weight
      - Random selection weighted by ELO score
   d. Return parent + next_step (parent.step.order + 1)
   e. mode = :child_generation

3. If no eligible parents:
   a. Check deficit mode:
      - Count active candidates in final step
      - If count < T: deficit = true
   b. If deficit:
      - Return parent = nil, next_step = first_step
      - mode = :base_generation
   c. Else:
      - Return all nil
      - mode = :no_work
```

### ELO-Weighted Raffle

```ruby
def weighted_raffle(candidates)
  total_weight = candidates.sum(&:elo_score)
  random_value = rand(0...total_weight)
  
  cumulative = 0
  candidates.each do |candidate|
    cumulative += candidate.elo_score
    return candidate if random_value < cumulative
  end
  
  candidates.last # fallback
end
```

### BuildJobPayload Command

**Inputs**:
- `parent_candidate` (ImageCandidate or nil)
- `pipeline_step` (PipelineStep)
- `pipeline_run` (PipelineRun)

**Outputs**:
- `job_payload` (Hash with ComfyUI job data)

**Logic**:

```ruby
payload = {
  workflow: JSON.parse(step.comfy_workflow_json),
  variables: {}
}

# Add run prompt if needed
if step.needs_run_prompt
  payload[:variables][:prompt] = run.variables['prompt']
end

# Add parent image path if needed
if step.needs_parent_image_path && parent_candidate
  payload[:variables][:parent_image] = parent_candidate.image_path
end

# Add all run variables if needed
if step.needs_run_variables
  payload[:variables].merge!(run.variables)
end

# Add target folder for output
payload[:output_folder] = "#{run.target_folder}/#{step.name.parameterize}"

payload
```

## Data Flow

```
SelectNextJob
  ↓
Returns: parent, step, mode
  ↓
BuildJobPayload (if mode != :no_work)
  ↓
Returns: job_payload
  ↓
Send to ComfyUI (future work)
  ↓
Create ImageCandidate on success (future work)
```

## Example Scenarios

### Scenario 1: Normal Child Generation
```
State:
- Step 2 has candidate A (ELO: 1200, 3 children)
- Step 2 has candidate B (ELO: 800, 2 children)
- Step 1 has candidate C (ELO: 1500, 4 children)

Result:
- Select from Step 2 (higher order)
- Raffle: A has 60% chance, B has 40%
- Winner: A (60% probability)
- Next step: 3
- Mode: :child_generation
```

### Scenario 2: Deficit Mode
```
State:
- All candidates have 5 children (N = 5)
- Final step has 3 active candidates (T = 10)

Result:
- No eligible parents
- Deficit detected (3 < 10)
- Parent: nil
- Next step: 1 (base generation)
- Mode: :base_generation
```

### Scenario 3: No Work
```
State:
- All candidates have 5 children
- Final step has 12 active candidates (T = 10)

Result:
- No eligible parents
- No deficit (12 >= 10)
- Mode: :no_work
```

## Configuration

```ruby
class JobOrchestrationConfig
  def self.max_children_per_node
    ENV.fetch('MAX_CHILDREN_PER_NODE', 5).to_i
  end
  
  def self.target_leaf_nodes
    ENV.fetch('TARGET_LEAF_NODES', 10).to_i
  end
end
```

## Pack Structure

```
packs/job_orchestration/
  package.yml
  app/
    commands/
      select_next_job.rb
      build_job_payload.rb
    services/
      job_orchestration_config.rb
  spec/
    commands/
      select_next_job_spec.rb
      build_job_payload_spec.rb
    services/
      job_orchestration_config_spec.rb
```

## Dependencies

- **Pipeline pack**: Read access to Pipeline, PipelineStep, ImageCandidate, PipelineRun models
- **GLCommand gem**: For command pattern implementation

## Risks / Trade-offs

### Risk: ELO raffle randomness in tests
**Mitigation**: 
- Use seeded random in tests
- Test distribution over many iterations
- Test edge cases (single candidate, equal ELO)

### Risk: N+1 queries in eligible parent search
**Mitigation**:
- Use includes/joins for eager loading
- Add N+1 detection tests
- Monitor query performance

### Risk: Race conditions in distributed workers
**Mitigation**:
- Document for future: use advisory locks
- Single worker for MVP
- Consider job queue with deduplication later

## Migration Plan

1. Create pack structure (safe, additive)
2. Implement SelectNextJob (no DB changes)
3. Implement BuildJobPayload (no DB changes)
4. Deploy without usage
5. Integrate with worker/scheduler in next phase

## Open Questions
- Should we log job selection decisions for debugging? **Decision**: Yes, add to command context
- Should raffle be truly random or deterministic for tests? **Decision**: Deterministic with seed
- What happens if pipeline has no PipelineRun? **Decision**: SelectNextJob returns :no_work
