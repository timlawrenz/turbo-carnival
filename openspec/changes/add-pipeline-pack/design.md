## Context
This change introduces the foundational data models for the AI image generation pipeline system. These models form the core of the domain logic and will be heavily referenced by other packs (job orchestration, voting UI, etc.). The design uses Packwerk to enforce clear boundaries and prevent coupling between domain concerns.

## Goals
- Create reusable pipeline configurations that can be run multiple times
- Support multi-stage workflows with ordered steps
- Track image generation as a tree structure with parent-child relationships
- Enable ELO-based ranking and intelligent job selection
- Support branch pruning via status state machine

## Non-Goals
- Job orchestration logic (separate pack/concern)
- Voting/ranking UI (separate pack/concern)
- ComfyUI integration (separate pack/concern)
- Configuration management for N and T parameters (deferred)

## Decisions

### Use Packwerk for Domain Organization
**Decision**: Organize models into a dedicated `packs/pipeline` pack.

**Rationale**: 
- Clear domain boundary for pipeline-related concerns
- Enforces dependency management and prevents circular dependencies
- Aligns with project conventions (see `openspec/project.md`)
- Makes it easier to test and evolve the domain independently

**Alternatives considered**:
- Put models in `app/models/` - Rejected because it doesn't provide clear boundaries and can lead to tangled dependencies as the codebase grows

### Pipeline Model for Reusability
**Decision**: Add a `Pipeline` model as a parent to `PipelineStep` to support running the same pipeline configuration multiple times.

**Rationale**:
- User explicitly requested the ability to "run the same pipelines over and over again"
- Separates pipeline configuration (reusable template) from pipeline execution (specific runs)
- Allows for multiple instances of the same workflow

**Alternatives considered**:
- Direct `PipelineStep` without parent - Rejected because it doesn't support reuse

### Self-Referential Tree Structure
**Decision**: Use `parent_id` self-referential foreign key on `ImageCandidate` to create tree structure.

**Rationale**:
- Simple, proven pattern for tree structures in Rails
- Efficient queries using recursive CTEs or ancestry gems if needed later
- Natural representation of generative workflow branching

### Cached `child_count` Column
**Decision**: Add `child_count` integer column to `ImageCandidate` with counter cache.

**Rationale**:
- Job selection algorithm needs to filter by `child_count < N` frequently
- Counter cache prevents N+1 queries
- Small data integrity risk acceptable (can be recalculated if needed)

### State Machine for Status
**Decision**: Use `state_machines-activerecord` gem for `ImageCandidate.status`.

**Rationale**:
- Project convention (see `openspec/project.md`)
- Provides clear transitions and validation
- Status is string type per conventions

**Valid states**: `active`, `rejected`

### Database Indexes
Key indexes to add:
- `pipeline_steps(pipeline_id)` - for step lookups by pipeline
- `pipeline_steps(order)` - for step ordering queries
- `image_candidates(pipeline_step_id)` - for candidates by step
- `image_candidates(parent_id)` - for tree traversal
- `image_candidates(status, child_count)` - composite for job selection queries
- `image_candidates(elo_score)` - for raffle selection

## Schema Design

### Pipelines Table
```ruby
create_table :pipelines do |t|
  t.string :name, null: false
  t.text :description
  t.timestamps
end

add_index :pipelines, :name
```

### Pipeline Steps Table
```ruby
create_table :pipeline_steps do |t|
  t.references :pipeline, null: false, foreign_key: true, index: true
  t.string :name, null: false
  t.integer :order, null: false
  t.text :comfy_workflow_json, null: false
  t.timestamps
end

add_index :pipeline_steps, [:pipeline_id, :order], unique: true
```

### Image Candidates Table
```ruby
create_table :image_candidates do |t|
  t.references :pipeline_step, null: false, foreign_key: true, index: true
  t.bigint :parent_id, index: true
  t.string :image_path
  t.integer :elo_score, null: false, default: 1000
  t.string :status, null: false, default: 'active'
  t.integer :child_count, null: false, default: 0
  t.timestamps
end

add_index :image_candidates, :parent_id
add_index :image_candidates, [:status, :child_count]
add_index :image_candidates, :elo_score
add_foreign_key :image_candidates, :image_candidates, column: :parent_id
```

## Model Associations

**Pipeline**:
- `has_many :pipeline_steps, -> { order(:order) }, dependent: :destroy`

**PipelineStep**:
- `belongs_to :pipeline`
- `has_many :image_candidates, dependent: :destroy`

**ImageCandidate**:
- `belongs_to :pipeline_step`
- `belongs_to :parent, class_name: 'ImageCandidate', optional: true`
- `has_many :children, class_name: 'ImageCandidate', foreign_key: :parent_id, dependent: :nullify`

## Validations

**Pipeline**:
- `name` presence

**PipelineStep**:
- `name` presence
- `order` presence, numericality (integer, >= 1)
- `comfy_workflow_json` presence
- Uniqueness of `order` scoped to `pipeline_id`

**ImageCandidate**:
- `elo_score` numericality (integer)
- `status` inclusion in ['active', 'rejected']
- `child_count` numericality (integer, >= 0)

## State Machine Transitions

**ImageCandidate** status transitions:
- `active` → `reject!` → `rejected`
- No transition from `rejected` back to `active` (permanent pruning)

## Risks / Trade-offs

### Risk: Counter Cache Drift
**Mitigation**: 
- Use built-in Rails counter cache for reliability
- Add rake task to recalculate if needed
- Monitor in development for anomalies

### Risk: Large Tree Depth
**Mitigation**: 
- Pipeline steps naturally limit depth (typically 4-5 steps)
- Can add depth validation if needed
- PostgreSQL handles recursive queries efficiently

### Risk: Pack Boundary Violations
**Mitigation**:
- Run `bin/packwerk check` in CI
- Document public API of pack clearly
- Use strong linting in pre-commit hooks

## Migration Plan

1. Create pack structure and configuration
2. Run migrations (additive, safe)
3. Deploy models without usage
4. Build dependent functionality in subsequent changes
5. No rollback needed (additive changes only)

## Open Questions
- Should we add soft deletes (paranoia) to any models? **Decision**: Defer until needed, use status state machine for now
- What's the max value for N (max children)? **Decision**: Make this configurable in a separate change, no hard limit in schema
- Should Pipeline have a status/active flag? **Decision**: Defer, simple existence implies active for now
