# pipeline Specification

## Purpose
TBD - created by archiving change add-run-create-interface. Update Purpose after archive.
## Requirements
### Requirement: Run Creation Interface
The system SHALL provide a web interface for users to create new pipeline runs.

#### Scenario: User creates run with basic settings
- **WHEN** a user navigates to the new run page
- **THEN** a form is displayed with fields for pipeline selection, run name, and target folder

#### Scenario: User submits valid run creation form
- **WHEN** a user selects pipeline "Portrait Pipeline", enters name "Gym Shoot", and submits the form
- **THEN** a new PipelineRun is created with status "pending"
- **AND** the user is redirected to the run detail page

#### Scenario: User creates run with custom variables
- **WHEN** a user creates a run with variables `{"prompt": "at the gym", "style": "cinematic"}`
- **THEN** the PipelineRun is created with those variables stored in the variables JSONB column

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

