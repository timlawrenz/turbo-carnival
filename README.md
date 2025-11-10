# Turbo Carnival

AI Image Generation Curation and Workflow Management Hub

## Overview

This application is a **Curation and Workflow Management Hub** for AI image generation. It sits between users and a generative AI backend (like ComfyUI) to manage multi-stage creative pipelines:

- Manages thousands of potential images in a tree structure
- Intelligently decides which image to generate next using ELO scoring
- Presents users with "A vs. B" voting decisions to guide the system
- Automates the multi-stage generation funnel (Base → Face Fix → Hand Fix → Upscale)
- Optimizes GPU usage by prioritizing work on promising branches
- Works autonomously to deliver fully-finished candidates


## Getting Started

### Prerequisites

- Ruby 3.4.5
- PostgreSQL
- Bundler
- ComfyUI instance running (for autonomous operation)

### Setup

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate

# Create example pipeline
bin/rails pipeline:setup_example

# Run tests
bin/rspec

# Validate pack boundaries
bin/packwerk check
bin/packwerk validate

# Code style check
bundle exec rubocop
```

### Quick Start: Voting Interface

The voting interface allows you to curate generated images using ELO-based ranking:

```bash
# Start the Rails server
bin/rails server

# Visit the voting interface
open http://localhost:3000/vote

# Vote by clicking on the better image
# Use "Kill" buttons to reject bad image branches
```

### Quick Start: Running Pipelines

```bash
# 1. Create an example pipeline with 4 steps
bin/rails pipeline:setup_example

# 2. Update ComfyUI workflow JSON for your actual workflows
#    (Edit in Rails console or database)

# 3. Start autonomous workers
bundle exec sidekiq

# 4. Create more runs as needed
bin/rails pipeline:create_run[3,"Beach Shoot","person on the beach, sunset"]
```

See `docs/PIPELINE_SETUP.md` for complete setup guide.

### Running Autonomous Workers

To run the system autonomously:

```bash
# Start the Sidekiq workers
bundle exec sidekiq

# This starts both workers:
# - JobSubmitterWorker: Selects and submits jobs every 10s
# - JobPollerWorker: Polls and processes jobs every 5s
```

Configure via environment variables:

```bash
# ComfyUI connection
COMFYUI_BASE_URL=http://localhost:8188  # API endpoint
COMFYUI_TIMEOUT=300                      # Request timeout (seconds)
COMFYUI_MAX_RETRIES=3                    # Retry attempts

# Worker intervals
COMFYUI_SUBMIT_INTERVAL=10  # Seconds between job submissions
COMFYUI_POLL_INTERVAL=5     # Seconds between status polls

# Job selection algorithm
PIPELINE_N=5   # Max children per candidate
PIPELINE_T=10  # Target final candidates

bundle exec sidekiq
```


## How It Works

### Core Data Models

**Pipeline** - Reusable pipeline configurations
- Has many ordered pipeline steps
- Has many pipeline runs
- Template that can be executed multiple times with different inputs

**PipelineStep** - Defines stages within a pipeline
- Belongs to a pipeline
- Stores ComfyUI workflow JSON template with `{{template_variables}}`
- Has ordered sequence (1, 2, 3...)
- Declares variable requirements via boolean flags (see Variable System below)
- Has many image candidates

**PipelineRun** - Individual execution of a pipeline
- Belongs to a pipeline
- Stores run-specific variables in JSONB (prompt, seed, run_name, persona_id, etc.)
- Has `target_folder` for organizing all images from this execution
- Status tracking: pending → running → completed/failed
- One run creates many ImageCandidates (100+) across all pipeline steps
- Variables are substituted into PipelineStep workflow templates

**ImageCandidate** - Represents a single ComfyUI job result (one image file)
- Belongs to a pipeline step AND a pipeline run
- Self-referential tree structure (parent/children)
- ELO score tracking (default 1000)
- State machine: `active` → `rejected`
- Counter cache for child count
- Stores `image_path` which can be referenced by child steps


### Variable System & Template Substitution

The variable system allows you to parameterize ComfyUI workflows and reuse pipeline definitions with different inputs.

#### How It Works

1. **Define template variables** in your ComfyUI workflow JSON using `{{variable_name}}` syntax
2. **Declare requirements** on each PipelineStep using boolean flags
3. **Provide values** when creating a PipelineRun via the `variables` JSONB field
4. **Template substitution** happens automatically when building job payloads

#### Template Variable Syntax

In your ComfyUI workflow JSON, use double curly braces for variables:

```json
{
  "107": {
    "inputs": {
      "seed": {{seed}}
    },
    "class_type": "Seed"
  },
  "121": {
    "inputs": {
      "text": "{{prompt}}"
    },
    "class_type": "Text Multiline"
  },
  "122": {
    "inputs": {
      "filename_prefix": "sarah1a3/{{run_name}}_base_image_",
      "images": ["77", 0]
    },
    "class_type": "SaveImage"
  }
}
```

**Important**: 
- Numeric values: `"seed": {{seed}}` (no quotes around template)
- String values: `"text": "{{prompt}}"` (quotes around entire string)
- The system does simple string replacement, so format accordingly

#### PipelineStep Variable Requirement Flags

Each PipelineStep declares what data it needs using boolean flags:

**`needs_run_prompt`** (deprecated - use `needs_run_variables` instead)
- Legacy flag: Makes `prompt` from PipelineRun variables available
- Use `needs_run_variables` for new implementations

**`needs_parent_image_path`**
- Automatically provides `{{parent_image_path}}` template variable
- Value comes from the parent ImageCandidate's `image_path` field
- Used for steps that process existing images (face fix, upscale, etc.)
- Example: `"image": "{{parent_image_path}}"`

**`needs_run_variables`**
- Provides ALL variables from the PipelineRun's `variables` JSONB field
- Most flexible option - use for any custom variables
- Variables become available as template substitutions
- Example variables: `prompt`, `seed`, `run_name`, `persona_id`, `style`, etc.

#### Variable Substitution Process

When `BuildJobPayload` constructs a job for ComfyUI:

```ruby
# 1. Load workflow JSON template from PipelineStep
workflow_json = pipeline_step.comfy_workflow_json

# 2. Replace all {{variable}} placeholders with actual values
pipeline_run.variables.each do |key, value|
  workflow_json.gsub!("{{#{key}}}", value.to_s)
end

# 3. If needs_parent_image_path, add parent's path
if pipeline_step.needs_parent_image_path
  workflow_json.gsub!("{{parent_image_path}}", parent_candidate.image_path)
end

# 4. Parse as JSON and submit to ComfyUI
workflow = JSON.parse(workflow_json)
```

#### Example: Complete Pipeline Setup

```ruby
# Create pipeline template (define once)
pipeline = Pipeline.create!(name: "Portrait Generation")

# Step 1: Base image generation
step1 = pipeline.pipeline_steps.create!(
  name: "Base Image",
  order: 1,
  comfy_workflow_json: File.read("workflows/base_image.json"),
  needs_run_variables: true  # Needs: seed, prompt, run_name
)

# Step 2: Face refinement
step2 = pipeline.pipeline_steps.create!(
  name: "Face Fix",
  order: 2,
  comfy_workflow_json: File.read("workflows/face_fix.json"),
  needs_run_variables: true,      # Needs: seed, run_name
  needs_parent_image_path: true   # Needs: parent image
)

# Step 3: Final upscale
step3 = pipeline.pipeline_steps.create!(
  name: "Upscale",
  order: 3,
  comfy_workflow_json: File.read("workflows/upscale.json"),
  needs_run_variables: true,      # Needs: seed, prompt, run_name
  needs_parent_image_path: true   # Needs: parent image
)

# Execute multiple times per day with different variables
run1 = pipeline.pipeline_runs.create!(
  name: "Morning Gym Session",
  target_folder: "runs/2025-11-10/gym",
  variables: {
    seed: 1000001,
    prompt: "person at the gym, athletic wear, exercising",
    run_name: "gym_session",
    persona_id: 123,
    style: "photorealistic"
  }
)

run2 = pipeline.pipeline_runs.create!(
  name: "Afternoon Coffee Shop",
  target_folder: "runs/2025-11-10/cafe",
  variables: {
    seed: 1000002,
    prompt: "person at coffee shop, casual clothes, reading book",
    run_name: "cafe_session",
    persona_id: 123,
    style: "photorealistic"
  }
)
```

#### ComfyUI Output Requirements

**Critical**: Your workflow MUST include a SaveImage node (or similar output node) or ComfyUI will reject it with "Prompt has no outputs".

```json
{
  "122": {
    "inputs": {
      "filename_prefix": "{{run_name}}_step1_",
      "images": ["77", 0]
    },
    "class_type": "SaveImage"
  }
}
```

**Output file structure**:
- ComfyUI saves to its `output/` directory
- Filename: `{filename_prefix}{number}_.png`
- Example: `gym_session_step1_00001_.png`
- The system retrieves this path via ComfyUI's history API
- Path is stored in ImageCandidate's `image_path` field for use by child steps

#### Common Variable Patterns

**Required for most workflows**:
- `seed` - Random seed for reproducibility (numeric, no quotes in template)
- `prompt` - Text description of desired image
- `run_name` - Identifier for organizing outputs

**Optional but recommended**:
- `persona_id` - Reference to character/subject being generated
- `style` - Art style descriptor ("photorealistic", "anime", etc.)
- `negative_prompt` - Things to avoid in generation
- `cfg_scale` - Classifier-free guidance strength
- `steps` - Number of diffusion steps

**Step-specific**:
- `parent_image_path` - Automatically provided when `needs_parent_image_path: true`
- Any custom parameters your ComfyUI workflow requires


## Examples

### Example Usage

#### Quick Start with Rake Task

```bash
# Create complete 4-step portrait pipeline with sample run
bin/rails pipeline:setup_example

# Create additional runs
bin/rails pipeline:create_run[3,"Cafe Shoot","person at coffee shop, reading"]
bin/rails pipeline:create_run[3,"Park Shoot","person in park, walking dog"]

# Start autonomous workers
bundle exec sidekiq
```

For detailed setup instructions, see `docs/PIPELINE_SETUP.md`.

#### Pipeline Setup (Manual)

```ruby
# Define pipeline template once
pipeline = Pipeline.create!(name: "Portrait Generation")

# Step 1: Base image - needs prompt, seed, run_name from variables
step1 = pipeline.pipeline_steps.create!(
  name: "Base Image", 
  order: 1,
  comfy_workflow_json: '{
    "seed_node": {"inputs": {"seed": {{seed}}}},
    "prompt_node": {"inputs": {"text": "{{prompt}}"}},
    "save_node": {"inputs": {"filename_prefix": "{{run_name}}_base_"}}
  }',
  needs_run_variables: true  # Provides: seed, prompt, run_name, and all other variables
)

# Step 2: Face fix - needs parent image and seed/run_name
step2 = pipeline.pipeline_steps.create!(
  name: "Face Fix",
  order: 2,
  comfy_workflow_json: '{
    "load_node": {"inputs": {"image": "{{parent_image_path}}"}},
    "seed_node": {"inputs": {"seed": {{seed}}}},
    "save_node": {"inputs": {"filename_prefix": "{{run_name}}_face_"}}
  }',
  needs_run_variables: true,      # Provides: seed, run_name
  needs_parent_image_path: true   # Provides: parent_image_path
)

# Step 3: Upscale - needs both prompt and parent image
step3 = pipeline.pipeline_steps.create!(
  name: "Upscale",
  order: 3,
  comfy_workflow_json: '{
    "load_node": {"inputs": {"image": "{{parent_image_path}}"}},
    "prompt_node": {"inputs": {"text": "{{prompt}}"}},
    "save_node": {"inputs": {"filename_prefix": "{{run_name}}_upscale_"}}
  }',
  needs_run_variables: true,      # Provides: prompt, seed, run_name
  needs_parent_image_path: true   # Provides: parent_image_path
)
```

#### Execute Pipeline Runs

```ruby
# Run multiple times per day with different variables
gym_run = pipeline.pipeline_runs.create!(
  name: "Gym Shoot",
  target_folder: "/storage/runs/2025-11-09/gym-shoot",
  variables: {
    seed: 1000001,
    prompt: "person at the gym, athletic wear",
    run_name: "gym_shoot",
    persona_id: 123
  }
)

home_run = pipeline.pipeline_runs.create!(
  name: "Home Shoot",
  target_folder: "/storage/runs/2025-11-09/home-shoot",
  variables: {
    seed: 1000002,
    prompt: "person at home, casual clothes",
    run_name: "home_shoot",
    persona_id: 123
  }
)

# Each run's variables are substituted into step workflows
# All generated images organized in the run's target_folder
# gym_shoot_base_00001_.png, gym_shoot_face_00001_.png, etc.
```

#### Select Next Job

```ruby
# The system intelligently decides which job to run next
result = SelectNextJob.call

case result.mode
when :child_generation
  # Generate child from selected parent candidate
  parent = result.parent_candidate
  next_step = result.next_step
  
  # Submit job to ComfyUI (workers do this automatically)
  SubmitJob.call(
    pipeline_step: next_step,
    pipeline_run: parent.pipeline_run,
    parent_candidate: parent
  )

when :base_generation
  # No eligible parents, but need more final candidates
  # Generate new base image
  step = result.next_step  # First step
  
  SubmitJob.call(
    pipeline_step: step,
    pipeline_run: PipelineRun.last  # Or create new run
  )

when :no_work
  # Pipeline is complete or no deficit
  # System is satisfied
end
```


### Monitoring

```ruby
# In Rails console

# Check pipeline status
pipeline = Pipeline.find(1)
pipeline.pipeline_runs.each do |run|
  puts "#{run.name}: #{run.image_candidates.count} images"
end

# View job queue
ComfyuiJob.in_flight.count   # Currently processing
ComfyuiJob.pending.count     # Waiting to submit
ComfyuiJob.completed.count   # Finished

# See what's next
result = SelectNextJob.call
puts "Next: #{result.mode} - #{result.next_step&.name}"
```


### Next Steps

The system is fully functional! Future enhancements:

- 🎨 Web UI for viewing ImageCandidates
- 🗳️ A/B voting interface for ELO score updates
- 📊 Dashboard showing pipeline progress and statistics
- 🔍 Image gallery with filtering and search
- 📈 Analytics on generation efficiency and costs



## Technical Details

## Tech Stack

- **Ruby 3.4.5** / **Rails 8.0.4** - Web framework
- **PostgreSQL** - Database
- **Puma** - Web server
- **Sidekiq 7.3.9** - Background job processing
- **Solid Cache/Queue/Cable** - Database-backed Rails infrastructure
- **Packwerk** + **packs-rails** - Modular architecture with enforced boundaries
- **ViewComponent** - Reusable UI components
- **Tailwind CSS v4** - Utility-first styling
- **GLCommand** - Business logic command pattern
- **State Machines** - Model state management
- **Pundit** - Authorization
- **RSpec** + **FactoryBot** - Testing


## Architecture

### Packs Structure

The application uses `packs-rails` for modular architecture:

```
packs/
  pipeline/           # Core domain models for pipeline management
    app/
      models/
        pipeline.rb
        pipeline_step.rb
        pipeline_run.rb
        image_candidate.rb
    spec/
      models/
      factories/
    package.yml
  
  job_orchestration/  # Intelligent job selection logic
    app/
      commands/
        select_next_job.rb
        build_job_payload.rb
      services/
        job_orchestration_config.rb
    spec/
      commands/
      services/
    package.yml
  
  comfyui/            # ComfyUI API integration
    app/
      models/
        comfyui_job.rb
      services/
        comfyui_client.rb
      commands/
        submit_job.rb
        poll_job_status.rb
        process_job_result.rb
      workers/
        job_submitter_worker.rb
        job_poller_worker.rb
    spec/
      models/
      commands/
      services/
      workers/
      factories/
    package.yml
```

### Core Data Models

**Pipeline** - Reusable pipeline configurations
- Has many ordered pipeline steps
- Has many pipeline runs
- Template that can be executed multiple times with different inputs

**PipelineStep** - Defines stages within a pipeline
- Belongs to a pipeline
- Stores ComfyUI workflow JSON template with `{{template_variables}}`
- Has ordered sequence (1, 2, 3...)
- Declares variable requirements via boolean flags (see Variable System below)
- Has many image candidates

**PipelineRun** - Individual execution of a pipeline
- Belongs to a pipeline
- Stores run-specific variables in JSONB (prompt, seed, run_name, persona_id, etc.)
- Has `target_folder` for organizing all images from this execution
- Status tracking: pending → running → completed/failed
- One run creates many ImageCandidates (100+) across all pipeline steps
- Variables are substituted into PipelineStep workflow templates

**ImageCandidate** - Represents a single ComfyUI job result (one image file)
- Belongs to a pipeline step AND a pipeline run
- Self-referential tree structure (parent/children)
- ELO score tracking (default 1000)
- State machine: `active` → `rejected`
- Counter cache for child count
- Stores `image_path` which can be referenced by child steps

### Variable System & Template Substitution

The variable system allows you to parameterize ComfyUI workflows and reuse pipeline definitions with different inputs.

#### How It Works

1. **Define template variables** in your ComfyUI workflow JSON using `{{variable_name}}` syntax
2. **Declare requirements** on each PipelineStep using boolean flags
3. **Provide values** when creating a PipelineRun via the `variables` JSONB field
4. **Template substitution** happens automatically when building job payloads

#### Template Variable Syntax

In your ComfyUI workflow JSON, use double curly braces for variables:

```json
{
  "107": {
    "inputs": {
      "seed": {{seed}}
    },
    "class_type": "Seed"
  },
  "121": {
    "inputs": {
      "text": "{{prompt}}"
    },
    "class_type": "Text Multiline"
  },
  "122": {
    "inputs": {
      "filename_prefix": "sarah1a3/{{run_name}}_base_image_",
      "images": ["77", 0]
    },
    "class_type": "SaveImage"
  }
}
```

**Important**: 
- Numeric values: `"seed": {{seed}}` (no quotes around template)
- String values: `"text": "{{prompt}}"` (quotes around entire string)
- The system does simple string replacement, so format accordingly

#### PipelineStep Variable Requirement Flags

Each PipelineStep declares what data it needs using boolean flags:

**`needs_run_prompt`** (deprecated - use `needs_run_variables` instead)
- Legacy flag: Makes `prompt` from PipelineRun variables available
- Use `needs_run_variables` for new implementations

**`needs_parent_image_path`**
- Automatically provides `{{parent_image_path}}` template variable
- Value comes from the parent ImageCandidate's `image_path` field
- Used for steps that process existing images (face fix, upscale, etc.)
- Example: `"image": "{{parent_image_path}}"`

**`needs_run_variables`**
- Provides ALL variables from the PipelineRun's `variables` JSONB field
- Most flexible option - use for any custom variables
- Variables become available as template substitutions
- Example variables: `prompt`, `seed`, `run_name`, `persona_id`, `style`, etc.

#### Variable Substitution Process

When `BuildJobPayload` constructs a job for ComfyUI:

```ruby
# 1. Load workflow JSON template from PipelineStep
workflow_json = pipeline_step.comfy_workflow_json

# 2. Replace all {{variable}} placeholders with actual values
pipeline_run.variables.each do |key, value|
  workflow_json.gsub!("{{#{key}}}", value.to_s)
end

# 3. If needs_parent_image_path, add parent's path
if pipeline_step.needs_parent_image_path
  workflow_json.gsub!("{{parent_image_path}}", parent_candidate.image_path)
end

# 4. Parse as JSON and submit to ComfyUI
workflow = JSON.parse(workflow_json)
```

#### Example: Complete Pipeline Setup

```ruby
# Create pipeline template (define once)
pipeline = Pipeline.create!(name: "Portrait Generation")

# Step 1: Base image generation
step1 = pipeline.pipeline_steps.create!(
  name: "Base Image",
  order: 1,
  comfy_workflow_json: File.read("workflows/base_image.json"),
  needs_run_variables: true  # Needs: seed, prompt, run_name
)

# Step 2: Face refinement
step2 = pipeline.pipeline_steps.create!(
  name: "Face Fix",
  order: 2,
  comfy_workflow_json: File.read("workflows/face_fix.json"),
  needs_run_variables: true,      # Needs: seed, run_name
  needs_parent_image_path: true   # Needs: parent image
)

# Step 3: Final upscale
step3 = pipeline.pipeline_steps.create!(
  name: "Upscale",
  order: 3,
  comfy_workflow_json: File.read("workflows/upscale.json"),
  needs_run_variables: true,      # Needs: seed, prompt, run_name
  needs_parent_image_path: true   # Needs: parent image
)

# Execute multiple times per day with different variables
run1 = pipeline.pipeline_runs.create!(
  name: "Morning Gym Session",
  target_folder: "runs/2025-11-10/gym",
  variables: {
    seed: 1000001,
    prompt: "person at the gym, athletic wear, exercising",
    run_name: "gym_session",
    persona_id: 123,
    style: "photorealistic"
  }
)

run2 = pipeline.pipeline_runs.create!(
  name: "Afternoon Coffee Shop",
  target_folder: "runs/2025-11-10/cafe",
  variables: {
    seed: 1000002,
    prompt: "person at coffee shop, casual clothes, reading book",
    run_name: "cafe_session",
    persona_id: 123,
    style: "photorealistic"
  }
)
```

#### ComfyUI Output Requirements

**Critical**: Your workflow MUST include a SaveImage node (or similar output node) or ComfyUI will reject it with "Prompt has no outputs".

```json
{
  "122": {
    "inputs": {
      "filename_prefix": "{{run_name}}_step1_",
      "images": ["77", 0]
    },
    "class_type": "SaveImage"
  }
}
```

**Output file structure**:
- ComfyUI saves to its `output/` directory
- Filename: `{filename_prefix}{number}_.png`
- Example: `gym_session_step1_00001_.png`
- The system retrieves this path via ComfyUI's history API
- Path is stored in ImageCandidate's `image_path` field for use by child steps

#### Common Variable Patterns

**Required for most workflows**:
- `seed` - Random seed for reproducibility (numeric, no quotes in template)
- `prompt` - Text description of desired image
- `run_name` - Identifier for organizing outputs

**Optional but recommended**:
- `persona_id` - Reference to character/subject being generated
- `style` - Art style descriptor ("photorealistic", "anime", etc.)
- `negative_prompt` - Things to avoid in generation
- `cfg_scale` - Classifier-free guidance strength
- `steps` - Number of diffusion steps

**Step-specific**:
- `parent_image_path` - Automatically provided when `needs_parent_image_path: true`
- Any custom parameters your ComfyUI workflow requires


## Current Status

### ✅ Complete Implementation

All core functionality is implemented and tested. The system can autonomously:
1. Select optimal jobs using ELO-weighted algorithm
2. Submit jobs to ComfyUI API
3. Poll for job completion
4. Download and save results
5. Create new ImageCandidates in the tree structure
6. Repeat continuously via background workers

### Implemented Features

**Pipeline Pack** ✅
- Core data models (Pipeline, PipelineStep, PipelineRun, ImageCandidate)
- Database migrations with optimized indexes
- State machine for ImageCandidate status
- Tree structure with parent/child relationships
- ELO scoring system for candidate ranking
- Comprehensive test coverage

**Pipeline Runs & Variable Templating** ✅
- PipelineRun model for tracking individual executions
- JSONB variable storage with GIN indexing
- Variable requirement flags on PipelineStep
- Support for running same pipeline 20+ times/day with different inputs
- Target folder organization for run images
- One run creates many ImageCandidates (100+) across all pipeline steps
- Full test coverage

**Job Orchestration** ✅
- SelectNextJob command using right-to-left priority algorithm
- ELO-weighted raffle for probabilistic candidate selection
- Autonomous deficit mode for base image generation
- BuildJobPayload command for variable substitution
- Configuration via environment variables (N=5, T=10)
- Returns job modes: :child_generation, :base_generation, :no_work
- Comprehensive test coverage

**ComfyUI Integration** ✅
- ComfyuiJob model for tracking submitted jobs through lifecycle
- ComfyUI API client with Faraday HTTP and automatic retry
- Database schema with JSONB for workflow payload and results
- Job status tracking: pending → submitted → running → completed/failed
- Configuration system (base URL, timeouts, retry limits)
- Full command layer:
  - SubmitJob: Creates job record and submits to ComfyUI API
  - PollJobStatus: Checks API for job progress updates
  - ProcessJobResult: Downloads images and creates ImageCandidates
- Background workers for autonomous operation:
  - JobSubmitterWorker: Continuously selects and submits new jobs
  - JobPollerWorker: Polls in-flight jobs and processes completions
- Comprehensive test coverage

**Image Voting & Curation** ✅
- ELO-based A vs B voting interface
- Triage-right strategy (prioritizes rightmost/completed images)
- Kill-left navigation for branch rejection
- RecordVote command with transaction safety
- RejectImageBranch command to prune failed branches
- Secure image serving through Rails (GET /images/:id)
- Responsive dark UI with Tailwind CSS
- 82 passing specs including vote recording and image serving

**Developer Tools** ✅
- Rake task: `pipeline:setup_example` - Creates complete 4-step pipeline
- Rake task: `pipeline:create_run` - Quick run creation from CLI
- Complete setup guide: `docs/PIPELINE_SETUP.md`

### Test Coverage

- **226+ passing specs** across all packs
- Pipeline pack: 79 specs (including voting tests)
- Job Orchestration: 25 specs
- ComfyUI Integration: 51 specs
- Request specs: 9 specs
- Developer Tools: 13 specs
- Zero failures
- 100% Packwerk compliance

### Example Usage

#### Quick Start with Rake Task

```bash
# Create complete 4-step portrait pipeline with sample run
bin/rails pipeline:setup_example

# Create additional runs
bin/rails pipeline:create_run[3,"Cafe Shoot","person at coffee shop, reading"]
bin/rails pipeline:create_run[3,"Park Shoot","person in park, walking dog"]

# Start autonomous workers
bundle exec sidekiq
```

For detailed setup instructions, see `docs/PIPELINE_SETUP.md`.

#### Pipeline Setup (Manual)

```ruby
# Define pipeline template once
pipeline = Pipeline.create!(name: "Portrait Generation")

# Step 1: Base image - needs prompt, seed, run_name from variables
step1 = pipeline.pipeline_steps.create!(
  name: "Base Image", 
  order: 1,
  comfy_workflow_json: '{
    "seed_node": {"inputs": {"seed": {{seed}}}},
    "prompt_node": {"inputs": {"text": "{{prompt}}"}},
    "save_node": {"inputs": {"filename_prefix": "{{run_name}}_base_"}}
  }',
  needs_run_variables: true  # Provides: seed, prompt, run_name, and all other variables
)

# Step 2: Face fix - needs parent image and seed/run_name
step2 = pipeline.pipeline_steps.create!(
  name: "Face Fix",
  order: 2,
  comfy_workflow_json: '{
    "load_node": {"inputs": {"image": "{{parent_image_path}}"}},
    "seed_node": {"inputs": {"seed": {{seed}}}},
    "save_node": {"inputs": {"filename_prefix": "{{run_name}}_face_"}}
  }',
  needs_run_variables: true,      # Provides: seed, run_name
  needs_parent_image_path: true   # Provides: parent_image_path
)

# Step 3: Upscale - needs both prompt and parent image
step3 = pipeline.pipeline_steps.create!(
  name: "Upscale",
  order: 3,
  comfy_workflow_json: '{
    "load_node": {"inputs": {"image": "{{parent_image_path}}"}},
    "prompt_node": {"inputs": {"text": "{{prompt}}"}},
    "save_node": {"inputs": {"filename_prefix": "{{run_name}}_upscale_"}}
  }',
  needs_run_variables: true,      # Provides: prompt, seed, run_name
  needs_parent_image_path: true   # Provides: parent_image_path
)
```

#### Execute Pipeline Runs

```ruby
# Run multiple times per day with different variables
gym_run = pipeline.pipeline_runs.create!(
  name: "Gym Shoot",
  target_folder: "/storage/runs/2025-11-09/gym-shoot",
  variables: {
    seed: 1000001,
    prompt: "person at the gym, athletic wear",
    run_name: "gym_shoot",
    persona_id: 123
  }
)

home_run = pipeline.pipeline_runs.create!(
  name: "Home Shoot",
  target_folder: "/storage/runs/2025-11-09/home-shoot",
  variables: {
    seed: 1000002,
    prompt: "person at home, casual clothes",
    run_name: "home_shoot",
    persona_id: 123
  }
)

# Each run's variables are substituted into step workflows
# All generated images organized in the run's target_folder
# gym_shoot_base_00001_.png, gym_shoot_face_00001_.png, etc.
```

#### Select Next Job

```ruby
# The system intelligently decides which job to run next
result = SelectNextJob.call

case result.mode
when :child_generation
  # Generate child from selected parent candidate
  parent = result.parent_candidate
  next_step = result.next_step
  
  # Submit job to ComfyUI (workers do this automatically)
  SubmitJob.call(
    pipeline_step: next_step,
    pipeline_run: parent.pipeline_run,
    parent_candidate: parent
  )

when :base_generation
  # No eligible parents, but need more final candidates
  # Generate new base image
  step = result.next_step  # First step
  
  SubmitJob.call(
    pipeline_step: step,
    pipeline_run: PipelineRun.last  # Or create new run
  )

when :no_work
  # Pipeline is complete or no deficit
  # System is satisfied
end
```

### Algorithm Highlights

**Right-to-Left Priority**: The system always prioritizes finishing work over starting new branches. A step-3 candidate with low ELO beats a step-1 candidate with high ELO.

**ELO-Weighted Raffle**: Within the same priority group, candidates are selected probabilistically based on their ELO scores. A candidate with ELO 1200 has 60% chance vs one with ELO 800 at 40%.

**Autonomous Deficit Mode**: When the final pipeline step has fewer than T (target) active candidates, the system automatically generates new base images to maintain the funnel.

**Configuration**:
- `PIPELINE_N` (default: 5) - Each candidate can have up to N children
- `PIPELINE_T` (default: 10) - Maintain at least T candidates in final step
- `COMFYUI_BASE_URL` (default: http://localhost:8188) - ComfyUI API endpoint
- `COMFYUI_POLL_INTERVAL` (default: 5) - Seconds between status checks
- `COMFYUI_SUBMIT_INTERVAL` (default: 10) - Seconds between job submissions
- `COMFYUI_TIMEOUT` (default: 300) - API request timeout in seconds
- `COMFYUI_MAX_RETRIES` (default: 3) - Max retries for failed API calls

### Monitoring

```ruby
# In Rails console

# Check pipeline status
pipeline = Pipeline.find(1)
pipeline.pipeline_runs.each do |run|
  puts "#{run.name}: #{run.image_candidates.count} images"
end

# View job queue
ComfyuiJob.in_flight.count   # Currently processing
ComfyuiJob.pending.count     # Waiting to submit
ComfyuiJob.completed.count   # Finished

# See what's next
result = SelectNextJob.call
puts "Next: #{result.mode} - #{result.next_step&.name}"
```

### Next Steps

The system is fully functional! Future enhancements:

- 🎨 Web UI for viewing ImageCandidates
- 🗳️ A/B voting interface for ELO score updates
- 📊 Dashboard showing pipeline progress and statistics
- 🔍 Image gallery with filtering and search
- 📈 Analytics on generation efficiency and costs


## Development

### Pre-commit Validation

Run the full validation suite before committing:

```bash
bin/rspec --fail-fast && bin/packwerk check && bin/packwerk validate && bundle exec rubocop --fail-fast
```


## Development Conventions

See `docs/CONVENTIONS.md` for full details:

- **No controller specs** - Use request specs for HTTP testing
- **GLCommand pattern** - Isolate business logic with rollback support
- **Isolated unit tests** - Mock external dependencies
- **State machines** - Use `state_machines-activerecord` for status fields
- **ViewComponents** - All UI components with preview files
- **Packwerk** - Enforce domain boundaries
- **Safe migrations** - Schema-only migrations, separate data tasks


## Project Documentation

- `docs/PIPELINE_SETUP.md` - Complete guide for creating and running pipelines
- `openspec/project.md` - Project conventions and tech stack details
- `docs/CONVENTIONS.md` - Coding conventions and testing strategy
- `docs/brainstorming.md` - Product description and algorithm details
- `openspec/changes/` - Active change proposals
- `openspec/specs/` - Capability specifications


## Testing

```bash
# Run all tests
bin/rspec

# Run specific pack tests
bin/rspec packs/pipeline/spec/

# Run specific file
bin/rspec spec/models/pipeline_spec.rb
```

Tests use:
- RSpec with shoulda-matchers
- FactoryBot for test data (automatically loads from packs)
- N+1 query detection with n_plus_one_control


## License

[To be determined]