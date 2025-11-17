# Pipeline Specification Deltas

## MODIFIED Requirements

### Requirement: The system SHALL provide a `PipelineRun` model to track individual executions of a pipeline with specific input variables
The system SHALL provide a `PipelineRun` model to track individual executions of a pipeline with a prompt and optional custom variables.

#### Scenario: User creates a pipeline run with a prompt
- **WHEN** a user creates a pipeline run with prompt "at the gym"
- **THEN** the run is created with `prompt` column set to "at the gym"

#### Scenario: Different prompts create separate runs
- **WHEN** the same pipeline is executed 3 times with different prompts
- **THEN** three separate PipelineRun records exist with different prompt values

#### Scenario: Run belongs to a pipeline
- **WHEN** a pipeline run is created
- **THEN** it belongs to a specific Pipeline template

#### Scenario: Run tracks all image candidates
- **WHEN** a pipeline run creates 30 base images, 10 face images, and 5 upscaled images
- **THEN** all 45 ImageCandidates belong to the same PipelineRun

## ADDED Requirements

### Requirement: Run Prompt as First-Class Attribute
The system SHALL store the run prompt as a dedicated `prompt` column on `pipeline_runs`.

#### Scenario: Prompt stored in column
- **WHEN** a run is created with prompt "at the beach"
- **THEN** `run.prompt` returns "at the beach"
- **AND** the prompt is NOT in the `variables` JSONB

#### Scenario: Prompt is queryable
- **WHEN** querying runs by prompt
- **THEN** standard SQL WHERE clauses can be used on the `prompt` column

#### Scenario: Nullable prompt
- **WHEN** a run is created without a prompt
- **THEN** `run.prompt` is NULL
- **AND** no error occurs

### Requirement: Run Name Consistency
The system SHALL use only the `name` column for run names, not `variables['run_name']`.

#### Scenario: Name stored in name column
- **WHEN** a run is created with name "Morning Shoot"
- **THEN** `run.name` returns "Morning Shoot"
- **AND** the name is NOT in the `variables` JSONB

#### Scenario: Views use name column
- **WHEN** a view displays a run name
- **THEN** it uses `run.name` without fallback to `variables['run_name']`

### Requirement: Prompt Merged into Job Variables
The system SHALL merge the `prompt` column back into the variables hash when building ComfyUI job payloads.

#### Scenario: Prompt available in job payload
- **WHEN** a job is submitted for a run with prompt "at the gym"
- **THEN** the job payload includes `variables: { prompt: "at the gym" }`

#### Scenario: Prompt merged with other variables
- **WHEN** a run has prompt "cyberpunk" and variables `{ style: "dark" }`
- **THEN** the job payload includes `variables: { prompt: "cyberpunk", style: "dark" }`

#### Scenario: Workflow templates can use prompt
- **WHEN** a workflow JSON contains `{{prompt}}`
- **THEN** it is replaced with the run's prompt value during job submission

## REMOVED Requirements

### Requirement: The system SHALL store run-specific variables in a JSONB column for flexible schema
**Reason**: Prompt and run_name are no longer stored in variables - they are dedicated columns

**Migration**: 
- `variables['prompt']` → `prompt` column
- `variables['run_name']` → `name` column  
- Other custom variables remain in JSONB `variables` column
