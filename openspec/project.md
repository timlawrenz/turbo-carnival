# Project Context

## Purpose
This is a **Curation and Workflow Management Hub** for AI image generation. It sits between users and a generative AI backend (like ComfyUI) to manage a multi-stage creative pipeline. The system:

- Manages the state of thousands of potential images in a tree structure
- Intelligently decides which image to generate next based on ELO scoring and pipeline state
- Presents users with "A vs. B" voting decisions to guide the system
- Automates the multi-stage generation funnel (Base → Face Fix → Hand Fix → Upscale)
- Optimizes GPU usage by prioritizing work on promising branches
- Minimizes time-to-candidate by working autonomously to deliver fully-finished candidates

## Tech Stack
- **Ruby on Rails 8.0.4** - Web framework
- **PostgreSQL** - Database
- **Puma** - Web server
- **Solid Cache** - Database-backed caching
- **Solid Queue** - Database-backed Active Job adapter
- **Solid Cable** - Database-backed Action Cable adapter
- **ViewComponent** - Reusable UI components
- **Tailwind CSS v4** - Modern utility-first CSS framework
- **Packwerk** - Code organization into domain-specific packs
- **GLCommand** (https://github.com/givelively/gl_command) - Business logic command pattern
- **State Machines ActiveRecord** - State management for models
- **Pundit** - Authorization
- **FactoryBot** - Test data generation
- **RSpec** - Testing framework
- **n_plus_one_control** - N+1 query detection

## Project Conventions

### Code Style
- Follow Rails Omakase styling (via rubocop-rails-omakase)
- Controllers focus on auth, validation, calling GLCommand, handling results
- Keep domain logic out of controllers
- Command class names must start with a verb (e.g., `SendEmail`, `CreateUser`)
- Use `state_machines-activerecord` for any models with state transitions (status columns should be string type)

### Architecture Patterns
- **Packwerk Packs**: Organize code into domain-specific packs in `packs/` subfolder with clear boundaries and dependencies
- **GLCommand Pattern**: Isolate business logic into single-responsibility commands that can be chained
  - Each command has a small, single purpose
  - Commands can be chained for complex multi-step operations
  - Commands implement `rollback` method for transactional behavior
  - Automatic rollback on failure: failed commands trigger rollback of all previously executed commands in reverse order
- **ViewComponents**: All UI elements use reusable ViewComponents in `app/components/`
  - Every component must have a preview file in `spec/components/previews/`
- **Service Layer**: Delegate complex logic to GLCommands or service layers, not controllers

### Testing Strategy
- **No Controller Specs**: Do not write controller specs
- **Isolated Unit Tests**: Cover classes, methods, and GLCommands with unit tests
  - Mock DB/external calls where reasonable
  - Test rollback logic for commands
  - Use GLCommand RSpec matchers for declarative testing
  - Use `build_context` method when stubbing commands
- **Request Specs**: Test auth (Pundit) and verify correct GLCommand is called with correct args, assert HTTP response
  - No mocks/stubs in request specs
- **Limited Integration Specs**: Only for critical end-to-end business flows
  - Full-stack specs hitting the DB
  - No mocks/stubs in integration specs
- **N+1 Query Prevention**: Implement N+1 tests using `n_plus_one_control` for data-fetching scenarios
- **FactoryBot**: Define factories in `spec/factories/` with proper naming (e.g., `user.rb`, `photo.rb`)
  - Use `FactoryBot.create` (not short notation)
- **Pre-commit command**: `bin/rspec --fail-fast && bin/packwerk check && bin/packwerk validate && bin/rubocop --fail-fast`

### Git Workflow
[To be documented - describe your branching strategy and commit conventions]

## Domain Context

### Core Data Models

**PipelineStep** - Defines the stages of the generative process (columns on the board):
- `name`: Human-readable name (e.g., "Base Generation", "Face Fix", "Hand Fix", "Final Upscale")
- `order`: Sequence number (1, 2, 3...) - crucial for right-to-left priority logic
- `comfy_workflow_json`: JSON of the ComfyUI workflow for this step

**ImageCandidate** - Represents a single image (node in a tree):
- `pipeline_step_id`: Links to the column this image belongs to
- `parent_id`: Links to the ImageCandidate used as source (null for Base images)
- `image_path`: Filepath to generated PNG
- `elo_score`: Rank calculated via user votes (default ~1000), used as "ticket count" in raffle
- `status`: Enum - `active` (default, viable) or `rejected` (pruned from future work)
- `child_count`: Cached count of direct children

### System Configuration
- **N (Max Children)**: Global setting (e.g., 5) - max children per ImageCandidate node
- **T (Target Leaf Nodes)**: Global setting (e.g., 10) - deficit target for autonomous work in right-most column

### Job Algorithm
The system uses a right-to-left priority algorithm with ELO-weighted raffle selection:
1. Find eligible parents (active status, child_count < N, not final step)
2. Prioritize by column descending (right-to-left ensures finishing work)
3. Isolate top priority column
4. Perform ELO raffle (weighted random selection for exploration/exploitation balance)
5. Handle autonomous deficit mode (generate new Base images if right-most column < T)

### Voting Interface
- **A vs. B Voting**: Primary interface using ELO ranking
- **Triage-Right**: Prioritize showing images from right-most column
- **Kill-Left Workflow**: Navigate left through parent hierarchy to find root cause of bad images
- Rejected nodes permanently stop all future work on that branch

## Important Constraints

### Migration Safety
- Migrations must only contain schema changes
- Use separate Rake tasks for data backfills/manipulation
- Follow multi-phase deployment for column changes: Add Col → Write Code → Backfill Task → Add Constraint → Read Code → Drop Old Col

### Security
- Brakeman for static security analysis
- Auth handled via Pundit policies

## External Dependencies
- **ComfyUI**: External generative AI backend for actual image generation
- System sends jobs to ComfyUI based on parent images and workflow JSON
