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

### Pre-commit Validation

Run the full validation suite before committing:

```bash
bin/rspec --fail-fast && bin/packwerk check && bin/packwerk validate && bundle exec rubocop --fail-fast
```

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
- Stores ComfyUI workflow JSON template
- Has ordered sequence (1, 2, 3...)
- Declares variable requirements via boolean flags:
  - `needs_run_prompt` - Step needs the original prompt
  - `needs_parent_image_path` - Step needs parent image reference
  - `needs_run_variables` - Step needs entire variable hash
- Has many image candidates

**PipelineRun** - Individual execution of a pipeline
- Belongs to a pipeline
- Stores run-specific variables in JSONB (prompt, persona_id, etc.)
- Has `target_folder` for organizing all images from this execution
- Status tracking: pending → running → completed/failed
- One run creates many ImageCandidates (100+) across all pipeline steps

**ImageCandidate** - Represents a single ComfyUI job result (one image file)
- Belongs to a pipeline step AND a pipeline run
- Self-referential tree structure (parent/children)
- ELO score tracking (default 1000)
- State machine: `active` → `rejected`
- Counter cache for child count

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

**Developer Tools** ✅
- Rake task: `pipeline:setup_example` - Creates complete 4-step pipeline
- Rake task: `pipeline:create_run` - Quick run creation from CLI
- Complete setup guide: `docs/PIPELINE_SETUP.md`

### Test Coverage

- **144 passing specs** across all packs
- Pipeline pack: 55 specs
- Job Orchestration: 25 specs
- ComfyUI Integration: 51 specs
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

step1 = pipeline.pipeline_steps.create!(
  name: "Base Image", order: 1,
  comfy_workflow_json: '{"workflow": "base", "prompt": "{{prompt}}"}',
  needs_run_prompt: true  # Declares it needs the prompt
)

step2 = pipeline.pipeline_steps.create!(
  name: "Face Fix", order: 2,
  comfy_workflow_json: '{"workflow": "face", "image": "{{parent_image_path}}"}',
  needs_parent_image_path: true  # Only needs parent image
)

step3 = pipeline.pipeline_steps.create!(
  name: "Upscale", order: 3,
  comfy_workflow_json: '{"workflow": "upscale", "prompt": "{{prompt}}", "image": "{{parent_image_path}}"}',
  needs_run_prompt: true,          # Needs both
  needs_parent_image_path: true
)
```

#### Execute Pipeline Runs

```ruby
# Run multiple times per day with different prompts
gym_run = pipeline.pipeline_runs.create!(
  name: "Gym Shoot",
  target_folder: "/storage/runs/2025-11-09/gym-shoot",
  variables: { prompt: "at the gym", persona_id: 123 }
)

home_run = pipeline.pipeline_runs.create!(
  name: "Home Shoot",
  target_folder: "/storage/runs/2025-11-09/home-shoot",
  variables: { prompt: "at home", persona_id: 123 }
)

# Each run creates many ImageCandidates across all steps
# All organized in the run's target_folder
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

## License

[To be determined]
