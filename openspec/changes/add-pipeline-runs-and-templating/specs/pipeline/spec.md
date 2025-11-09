## ADDED Requirements

### Requirement: Pipeline Run Tracking
The system SHALL provide a `PipelineRun` model to track individual executions of a pipeline with specific input variables.

#### Scenario: Create pipeline run with variables
- **WHEN** a user creates a pipeline run with a prompt "at the gym"
- **THEN** the run is created with variables stored in JSONB format

#### Scenario: Multiple runs of same pipeline
- **WHEN** the same pipeline is executed 3 times with different prompts
- **THEN** three separate PipelineRun records exist with different variables

#### Scenario: Link run to pipeline
- **WHEN** a pipeline run is created
- **THEN** it belongs to a specific Pipeline template

#### Scenario: Many candidates per run
- **WHEN** a pipeline run creates 30 base images, 10 face images, and 5 upscaled images
- **THEN** all 45 ImageCandidates belong to the same PipelineRun

### Requirement: Run Target Folder
The system SHALL store a target folder path for each PipelineRun to organize all images from that execution.

#### Scenario: Set target folder
- **WHEN** a pipeline run is created with target_folder "/storage/runs/gym-shoot"
- **THEN** the folder path is persisted

#### Scenario: Image paths use run folder
- **WHEN** an image candidate is created for a run
- **THEN** its image_path can be constructed using the run's target_folder

#### Scenario: Organize by run
- **WHEN** all images for "Gym Shoot" are stored in `/storage/runs/gym-shoot/`
- **THEN** all candidates from different steps are in subdirectories of that folder

### Requirement: Run Variable Storage
The system SHALL store run-specific variables in a JSONB column for flexible schema.

#### Scenario: Store prompt variable
- **WHEN** a run is created with prompt: "at home"
- **THEN** `variables["prompt"]` contains "at home"

#### Scenario: Store multiple variables
- **WHEN** a run is created with prompt, persona_id, and style
- **THEN** all variables are stored in the JSONB column

#### Scenario: Query by variable value
- **WHEN** querying runs by a specific prompt
- **THEN** JSONB GIN index enables efficient lookups

### Requirement: Run Status Tracking
The system SHALL track the status of each pipeline run.

#### Scenario: Default pending status
- **WHEN** a new pipeline run is created
- **THEN** status is "pending"

#### Scenario: Valid status transitions
- **WHEN** updating run status
- **THEN** only values ['pending', 'running', 'completed', 'failed'] are accepted

## MODIFIED Requirements

### Requirement: Pipeline Step Variable Requirements
The system SHALL allow PipelineStep to declare what variables it needs via boolean flags.

#### Scenario: Step needs run prompt
- **WHEN** a step is configured with `needs_run_prompt: true`
- **THEN** the flag is persisted and queryable

#### Scenario: Step needs parent image path
- **WHEN** a step is configured with `needs_parent_image_path: true`
- **THEN** the flag indicates parent image reference is required

#### Scenario: Step needs both variables
- **WHEN** a step is configured with both `needs_run_prompt` and `needs_parent_image_path`
- **THEN** both flags are true and step can access both variables

#### Scenario: Step needs entire variable hash
- **WHEN** a step is configured with `needs_run_variables: true`
- **THEN** step can access entire variables JSONB column

#### Scenario: Default variable requirements
- **WHEN** a new pipeline step is created without specifying variable flags
- **THEN** all variable requirement flags default to false

### Requirement: Image Candidate Run Association
The system SHALL associate each ImageCandidate with a specific PipelineRun for traceability.

#### Scenario: Candidate belongs to run
- **WHEN** an image candidate is created for a pipeline run
- **THEN** it is associated with that specific run instance

#### Scenario: Multiple candidates per run
- **WHEN** a pipeline run generates multiple images at step 1
- **THEN** all candidates link to the same pipeline run

#### Scenario: Backwards compatibility for existing candidates
- **WHEN** querying existing image candidates without a run
- **THEN** `pipeline_run_id` is null and candidate still works

#### Scenario: Query candidates by run
- **WHEN** retrieving all candidates for a specific run
- **THEN** all ImageCandidates with matching `pipeline_run_id` are returned

## MODIFIED Requirements

### Requirement: Pipeline Configuration
The system SHALL provide a `Pipeline` model to store reusable pipeline configurations that can be executed multiple times.

**(Content remains same, adding association)**

**New association**: `has_many :pipeline_runs`

#### Scenario: Pipeline with multiple runs
- **WHEN** a pipeline is executed 20 times in one day
- **THEN** the pipeline has 20 associated pipeline_runs

### Requirement: Pipeline Step Association
The system SHALL associate each `ImageCandidate` with a specific `PipelineStep` to track which stage of the pipeline produced it.

**(Content mostly unchanged, adding run context)**

#### Scenario: Candidate with step and run context
- **WHEN** an image candidate is created
- **THEN** it belongs to both a PipelineStep and a PipelineRun

## ADDED Requirements

### Requirement: Variable Flag Querying
The system SHALL enable efficient querying of steps by their variable requirements.

#### Scenario: Find steps needing run prompt
- **WHEN** querying for all steps that need the run prompt
- **THEN** return all steps where `needs_run_prompt: true`

#### Scenario: Find steps needing parent image
- **WHEN** querying for steps requiring parent image paths
- **THEN** return all steps where `needs_parent_image_path: true`

### Requirement: Run and Step Integration
The system SHALL enable accessing required variables for job construction.

#### Scenario: Access run prompt for step
- **WHEN** a step has `needs_run_prompt: true`
- **THEN** the prompt can be accessed via `pipeline_run.variables["prompt"]`

#### Scenario: Access parent image path
- **WHEN** a step has `needs_parent_image_path: true`
- **THEN** path is accessed via `image_candidate.parent.image_path`

#### Scenario: Access multiple variables
- **WHEN** a step needs both prompt and parent image
- **THEN** both can be accessed from pipeline_run and parent candidate

### Requirement: JSONB Index Performance
The system SHALL index run variables for efficient querying.

#### Scenario: GIN index on variables
- **WHEN** querying pipeline runs by variable values
- **THEN** PostgreSQL GIN index is used for performance

### Requirement: Run Validation
The system SHALL validate PipelineRun attributes to ensure data integrity.

#### Scenario: Pipeline required
- **WHEN** creating a run without a pipeline
- **THEN** validation fails

#### Scenario: Variables required
- **WHEN** creating a run without variables column
- **THEN** validation fails (but empty hash {} is valid)

#### Scenario: Valid status required
- **WHEN** setting run status to invalid value
- **THEN** validation fails
