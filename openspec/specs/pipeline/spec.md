# pipeline Specification

## Purpose
TBD - created by archiving change add-run-create-interface. Update Purpose after archive.
## Requirements
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

### Requirement: Run Creation Command
The system SHALL implement a GLCommand for run creation with proper error handling and rollback support.

#### Scenario: Command creates run successfully
- **WHEN** CreatePipelineRun command is executed with valid parameters
- **THEN** a PipelineRun record is created
- **AND** the command returns success

#### Scenario: Command rolls back on failure
- **WHEN** CreatePipelineRun command fails during execution
- **THEN** any created records are rolled back
- **AND** the command returns failure with error details

#### Scenario: Command validates required parameters
- **WHEN** CreatePipelineRun is called without a pipeline_id
- **THEN** the command fails with a validation error
- **AND** no database changes occur

### Requirement: Run Creation Routes
The system SHALL provide RESTful routes for run creation.

#### Scenario: GET new run form
- **WHEN** a user visits /runs/new
- **THEN** the new run form is displayed

#### Scenario: POST create run
- **WHEN** a user submits valid form data to POST /runs
- **THEN** a new run is created
- **AND** the user is redirected to GET /runs/:id

#### Scenario: POST create run with errors
- **WHEN** a user submits invalid form data to POST /runs
- **THEN** the form is re-rendered with error messages
- **AND** the HTTP status is 422 Unprocessable Entity

### Requirement: Default Run Settings
The system SHALL apply sensible defaults when creating runs.

#### Scenario: Run created with default status
- **WHEN** a run is created without specifying status
- **THEN** the status is set to "pending"

#### Scenario: Run created with default variables
- **WHEN** a run is created without specifying variables
- **THEN** the variables column is set to an empty JSON object {}

#### Scenario: Run created with generated target folder
- **WHEN** a run is created without specifying a target folder
- **THEN** a target folder is auto-generated based on run name and timestamp

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

