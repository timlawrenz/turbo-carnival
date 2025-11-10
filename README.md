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

### Setup

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate

# Run tests
bin/rspec

# Validate pack boundaries
bin/packwerk check
bin/packwerk validate

# Code style check
bundle exec rubocop
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

✅ **Pipeline Pack Implemented**
- Core data models (Pipeline, PipelineStep, ImageCandidate)
- Database migrations with optimized indexes
- State machine for ImageCandidate status
- Tree structure with parent/child relationships
- ELO scoring system for candidate ranking
- Comprehensive test coverage (55 specs passing)
- Pack boundaries validated

✅ **Pipeline Runs & Variable Templating Implemented**
- PipelineRun model for tracking individual executions
- JSONB variable storage with GIN indexing
- Variable requirement flags on PipelineStep
- Support for running same pipeline 20+ times/day with different inputs
- Target folder organization for run images
- One run creates many ImageCandidates (100+) across all pipeline steps
- Full test coverage

✅ **Job Orchestration Implemented**
- SelectNextJob command using right-to-left priority algorithm
- ELO-weighted raffle for probabilistic candidate selection
- Autonomous deficit mode for base image generation
- BuildJobPayload command for variable substitution
- Configuration via environment variables (N=5, T=10)
- Returns job modes: :child_generation, :base_generation, :no_work
- Comprehensive test coverage (25 specs, 80 total)

### Example Usage

#### Pipeline Setup

```ruby
# Define pipeline template once
pipeline = Pipeline.create!(name: "Portrait Generation")

step1 = pipeline.pipeline_steps.create!(
  name: "Base Image", order: 1,
  comfy_workflow_json: '{"workflow": "base"}',
  needs_run_prompt: true  # Declares it needs the prompt
)

step2 = pipeline.pipeline_steps.create!(
  name: "Face Fix", order: 2,
  comfy_workflow_json: '{"workflow": "face"}',
  needs_parent_image_path: true  # Only needs parent image
)

step3 = pipeline.pipeline_steps.create!(
  name: "Upscale", order: 3,
  comfy_workflow_json: '{"workflow": "upscale"}',
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
  
  # Build the job payload
  payload = BuildJobPayload.call(
    pipeline_step: next_step,
    pipeline_run: parent.pipeline_run,
    parent_candidate: parent
  )
  
  # Send payload.job_payload to ComfyUI
  # payload.job_payload includes:
  #   - workflow: parsed JSON
  #   - variables: { prompt, parent_image, etc }
  #   - output_folder: constructed path

when :base_generation
  # No eligible parents, but need more final candidates
  # Generate new base image
  step = result.next_step  # First step
  
  payload = BuildJobPayload.call(
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
- `MAX_CHILDREN_PER_NODE` (default: 5) - Each candidate can have up to N children
- `TARGET_LEAF_NODES` (default: 10) - Maintain at least T candidates in final step

🚧 **In Progress**
- ComfyUI API integration
- Result processing and image storage
- Voting/ranking UI for ELO updates

## License

[To be determined]
