# Pipeline Specification Deltas

## MODIFIED Requirements

### Requirement: Run Creation Interface
The system SHALL provide a web interface for users to create new pipeline runs with prompt as a separate field.

#### Scenario: User creates run with basic settings
- **WHEN** a user navigates to the new run page
- **THEN** a form is displayed with fields for pipeline selection, run name, prompt, and target folder

#### Scenario: User submits valid run creation form
- **WHEN** a user selects pipeline "Portrait Pipeline", enters name "Gym Shoot", enters prompt "at the gym", and submits the form
- **THEN** a new PipelineRun is created with status "pending"
- **AND** the prompt is stored in the `prompt` column
- **AND** the user is redirected to the run detail page

#### Scenario: User creates run with custom variables
- **WHEN** a user creates a run with prompt "at the gym" and variables `{"style": "cinematic"}`
- **THEN** the PipelineRun is created with prompt in the `prompt` column
- **AND** other variables are stored in the variables JSONB column

#### Scenario: User attempts to create run without required fields
- **WHEN** a user submits the form without selecting a pipeline
- **THEN** validation errors are displayed
- **AND** no PipelineRun is created

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

