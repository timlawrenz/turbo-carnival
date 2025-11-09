## Context
This change enables Pipeline reusability by separating the template (Pipeline) from its execution (PipelineRun). Each run represents one complete execution of the entire pipeline with specific inputs (prompts, parameters) and may create hundreds of ImageCandidates across all steps. Steps declare what variables they need, enabling dynamic ComfyUI job construction.

**Key Distinction**:
- **PipelineRun** = One complete execution of the pipeline (e.g., "Gym Shoot")
  - Creates MANY ImageCandidates (potentially 100+ across all steps)
  - Has one `target_folder` where all images from this run are stored
  - NOT the same as a single ComfyUI job
- **ImageCandidate** = One individual ComfyUI render job result
  - Represents a single image file
  - Belongs to one PipelineStep AND one PipelineRun

**Example**: A PipelineRun "Gym Shoot" might create:
- 30 base images (step 1)
- 10 face-fixed images (step 2, from best 10 base images)
- 5 hand-fixed images (step 3, from best 5 face images)
- 2 upscaled images (step 4, from best 2 hand images)
= 47 total ImageCandidates, all in `/storage/runs/2025-11-09/gym-shoot/`

## Goals
- Support running the same pipeline template multiple times per day with different inputs
- Enable step-level variable requirements (prompt, parent image path, etc.)
- Store run-specific variables (prompt, persona, parameters)
- Link all image candidates from one execution to their PipelineRun
- Organize all images from one run into a single target folder

## Non-Goals
- ComfyUI job construction logic (separate concern)
- Actual variable substitution/templating engine (defer to implementation)
- Workflow scheduling (separate concern)

## Decisions

### PipelineRun Model
**Decision**: Add `PipelineRun` model to track individual executions of a pipeline.

**Rationale**:
- Separates reusable template (Pipeline) from execution instance (PipelineRun)
- Allows same pipeline to be run 20+ times with different prompts
- Stores run-specific variables in JSONB for flexibility
- Links all ImageCandidates to a specific run for traceability

**Alternatives considered**:
- Store variables on Pipeline - Rejected: loses run-specific data
- Store variables on ImageCandidate - Rejected: duplicates data across all candidates

### Variable Requirement Flags on PipelineStep
**Decision**: Add boolean flags to PipelineStep to declare what variables each step needs.

**Rationale**:
- Makes variable requirements explicit and queryable
- Simple boolean columns are fast to query
- Clear contract for what each step needs
- Examples: `needs_run_prompt`, `needs_parent_image_path`

**Alternatives considered**:
- JSONB column with variable names - Rejected: harder to query, validate
- External configuration file - Rejected: separates schema from data

### Variable Storage Format
**Decision**: Use JSONB column on PipelineRun to store run-specific variables.

**Rationale**:
- Flexible schema for different variable types
- Native PostgreSQL support with indexing
- Easy to add new variables without migrations
- Example: `{"prompt": "at the gym", "persona_id": 123, "style": "realistic"}`

**Alternatives considered**:
- Individual columns - Rejected: inflexible, requires migration for new variables
- Serialized JSON text - Rejected: no PostgreSQL JSONB benefits

## Schema Design

### Pipeline Runs Table
```ruby
create_table :pipeline_runs do |t|
  t.references :pipeline, null: false, foreign_key: true, index: true
  t.string :name
  t.string :target_folder  # Base folder for all images from this run
  t.jsonb :variables, null: false, default: {}
  t.string :status, null: false, default: "pending"
  t.timestamps
end

add_index :pipeline_runs, :status
add_index :pipeline_runs, :variables, using: :gin
```

### Pipeline Steps Update
```ruby
add_column :pipeline_steps, :needs_run_prompt, :boolean, default: false, null: false
add_column :pipeline_steps, :needs_parent_image_path, :boolean, default: false, null: false
add_column :pipeline_steps, :needs_run_variables, :boolean, default: false, null: false
```

### Image Candidates Update
```ruby
add_reference :image_candidates, :pipeline_run, foreign_key: true, index: true
# Note: pipeline_run_id can be null for backwards compatibility during migration
```

## Model Associations

**PipelineRun**:
- `belongs_to :pipeline`
- `has_many :image_candidates, dependent: :destroy`

**Pipeline**:
- Existing: `has_many :pipeline_steps`
- New: `has_many :pipeline_runs, dependent: :destroy`

**ImageCandidate**:
- Existing: `belongs_to :pipeline_step`
- New: `belongs_to :pipeline_run, optional: true` (optional for migration compatibility)

## Validations

**PipelineRun**:
- `pipeline` presence
- `variables` presence (can be empty hash)
- `status` inclusion in ['pending', 'running', 'completed', 'failed']

**PipelineStep**:
- No additional validations for boolean flags (default false is acceptable)

## Example Usage

### Creating a Pipeline Template
```ruby
pipeline = Pipeline.create!(name: "Portrait Generation")
step1 = pipeline.pipeline_steps.create!(
  name: "Base Image",
  order: 1,
  comfy_workflow_json: '{"workflow": "base"}',
  needs_run_prompt: true  # This step needs the prompt
)
step2 = pipeline.pipeline_steps.create!(
  name: "Face Fix",
  order: 2,
  comfy_workflow_json: '{"workflow": "face"}',
  needs_parent_image_path: true  # This step needs parent image
)
step3 = pipeline.pipeline_steps.create!(
  name: "Upscale",
  order: 3,
  comfy_workflow_json: '{"workflow": "upscale"}',
  needs_run_prompt: true,  # Needs original prompt
  needs_parent_image_path: true  # AND parent image
)
```

### Executing the Pipeline Multiple Times
```ruby
# Run 1: At the gym - will create many images across all steps
run1 = pipeline.pipeline_runs.create!(
  name: "Gym Shoot",
  target_folder: "/storage/runs/2025-11-09/gym-shoot",
  variables: { prompt: "at the gym", persona_id: 123, style: "realistic" }
)

# Run 2: At home - separate folder for organizational clarity
run2 = pipeline.pipeline_runs.create!(
  name: "Home Shoot",
  target_folder: "/storage/runs/2025-11-09/home-shoot",
  variables: { prompt: "at home", persona_id: 123, style: "realistic" }
)

# Run 3: At café
run3 = pipeline.pipeline_runs.create!(
  name: "Café Shoot",
  target_folder: "/storage/runs/2025-11-09/cafe-shoot",
  variables: { prompt: "at a café", persona_id: 123, style: "realistic" }
)
```

### Generating Images for a Run
```ruby
# For run1, generate base images at step 1 (might create 30 images)
step1 = pipeline.pipeline_steps.find_by(order: 1)

# Each ImageCandidate is ONE ComfyUI job result
candidate1 = ImageCandidate.create!(
  pipeline_step: step1,
  pipeline_run: run1,
  image_path: "#{run1.target_folder}/base/image_001.png"
)

candidate2 = ImageCandidate.create!(
  pipeline_step: step1,
  pipeline_run: run1,
  image_path: "#{run1.target_folder}/base/image_002.png"
)

# ... 28 more base images for this run

# Later, face fix step (step 2) might create 10 images from the best 10 base images
step2 = pipeline.pipeline_steps.find_by(order: 2)
face_candidate1 = ImageCandidate.create!(
  pipeline_step: step2,
  pipeline_run: run1,  # Same run!
  parent: candidate1,   # Parent is from step 1
  image_path: "#{run1.target_folder}/face/image_001.png"
)

# This run might create 100+ total ImageCandidates across all steps
# All stored in run1.target_folder

# Job construction would use:
# - step1.comfy_workflow_json (the template)
# - run1.variables["prompt"] (because step1.needs_run_prompt == true)
# - run1.target_folder (to know where to save the result)
```

## Variable Access Patterns

Steps can declare what they need:
- `needs_run_prompt: true` → Access via `pipeline_run.variables["prompt"]`
- `needs_parent_image_path: true` → Access via `image_candidate.parent.image_path`
- `needs_run_variables: true` → Access entire `pipeline_run.variables` hash

## Risks / Trade-offs

### Risk: Variable Schema Inconsistency
**Mitigation**:
- Document expected variable keys per pipeline type
- Add application-level validation for required keys
- Consider adding JSON schema validation in future

### Risk: Backwards Compatibility
**Mitigation**:
- Make `pipeline_run_id` optional on ImageCandidate
- Existing candidates without runs continue to work
- New candidates should always have a run

### Risk: JSONB Query Performance
**Mitigation**:
- GIN index on variables column
- Limit JSONB queries to specific keys
- Monitor query performance

## Migration Plan

1. Add `pipeline_runs` table (additive, safe)
2. Add variable flags to `pipeline_steps` (additive, defaults to false)
3. Add `pipeline_run_id` to `image_candidates` (nullable, safe)
4. Deploy models and associations
5. Update application code to create PipelineRuns
6. Backfill existing ImageCandidates with PipelineRuns (optional, separate task)

## Open Questions
- Should we validate specific variable keys per pipeline type? **Decision**: Defer to application layer
- Should PipelineRun have a state machine like ImageCandidate? **Decision**: Yes, simple status string for now
- Maximum runs per pipeline? **Decision**: No hard limit, monitor in production
