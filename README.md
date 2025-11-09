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
        image_candidate.rb
    spec/
      models/
      factories/
    package.yml
```

### Core Data Models

**Pipeline** - Reusable pipeline configurations
- Has many ordered pipeline steps
- Can be run multiple times

**PipelineStep** - Defines stages within a pipeline
- Belongs to a pipeline
- Stores ComfyUI workflow JSON
- Has ordered sequence (1, 2, 3...)
- Has many image candidates

**ImageCandidate** - Represents a single image node in the generation tree
- Belongs to a pipeline step
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
- Comprehensive test coverage (33 specs passing)
- Pack boundaries validated

🚧 **In Progress**
- Job orchestration logic
- Voting/ranking UI
- ComfyUI integration

## License

[To be determined]
