## ADDED Requirements

### Requirement: Job Selection Configuration
The system SHALL provide configuration for job orchestration parameters.

#### Scenario: Max children per node
- **WHEN** accessing the max children configuration
- **THEN** it returns the configured N value (default 5)

#### Scenario: Target leaf nodes
- **WHEN** accessing the target leaf nodes configuration
- **THEN** it returns the configured T value (default 10)

#### Scenario: Environment variable override
- **WHEN** MAX_CHILDREN_PER_NODE environment variable is set to 7
- **THEN** configuration returns 7

### Requirement: Eligible Parent Selection
The system SHALL find eligible ImageCandidates that can have children generated.

#### Scenario: Active candidates with room for children
- **WHEN** querying for eligible parents with N=5
- **THEN** return only active candidates with child_count < 5

#### Scenario: Exclude rejected candidates
- **WHEN** a candidate status is 'rejected'
- **THEN** it is not included in eligible parents

#### Scenario: Exclude candidates at final step
- **WHEN** a candidate is at the final pipeline step
- **THEN** it is not included in eligible parents

#### Scenario: Exclude candidates with max children
- **WHEN** a candidate has child_count = N
- **THEN** it is not included in eligible parents

### Requirement: Right-to-Left Priority
The system SHALL prioritize candidates from higher-order pipeline steps.

#### Scenario: Candidates at different steps
- **WHEN** Step 1 has candidates and Step 3 has candidates
- **THEN** only Step 3 candidates are considered for selection

#### Scenario: Prioritize finishing work
- **WHEN** Step 2 has high ELO candidates and Step 3 has low ELO candidates
- **THEN** Step 3 candidates are selected regardless of ELO

#### Scenario: Same step priority
- **WHEN** multiple candidates are at Step 2
- **THEN** ELO raffle determines selection within that group

### Requirement: ELO-Weighted Raffle Selection
The system SHALL use weighted random selection based on ELO scores.

#### Scenario: Higher ELO has higher probability
- **WHEN** candidate A has ELO 1200 and candidate B has ELO 800
- **THEN** candidate A has 60% probability and B has 40%

#### Scenario: Equal ELO has equal probability
- **WHEN** two candidates have ELO 1000
- **THEN** each has 50% probability

#### Scenario: Single candidate selection
- **WHEN** only one eligible candidate exists
- **THEN** that candidate is always selected

#### Scenario: Low ELO still has chance
- **WHEN** candidate A has ELO 1900 and candidate B has ELO 100
- **THEN** candidate B has 5% chance (exploration)

### Requirement: Next Step Determination
The system SHALL determine the next pipeline step for child generation.

#### Scenario: Child generation next step
- **WHEN** selected parent is at Step 2
- **THEN** next step is Step 3

#### Scenario: Base generation first step
- **WHEN** mode is base generation
- **THEN** next step is Step 1

### Requirement: Autonomous Deficit Mode
The system SHALL automatically generate base images when final step has too few candidates.

#### Scenario: Deficit detected
- **WHEN** no eligible parents and final step has 7 active candidates (T=10)
- **THEN** trigger base generation mode

#### Scenario: No deficit
- **WHEN** no eligible parents and final step has 12 active candidates (T=10)
- **THEN** return no work mode

#### Scenario: Deficit threshold
- **WHEN** final step has exactly T active candidates
- **THEN** no deficit (count >= T)

### Requirement: Work Mode Detection
The system SHALL indicate what type of work is available.

#### Scenario: Child generation mode
- **WHEN** eligible parents exist
- **THEN** mode is :child_generation

#### Scenario: Base generation mode
- **WHEN** no eligible parents and deficit exists
- **THEN** mode is :base_generation

#### Scenario: No work mode
- **WHEN** no eligible parents and no deficit
- **THEN** mode is :no_work

### Requirement: Job Payload Construction
The system SHALL build ComfyUI job payloads with variable substitution.

#### Scenario: Include workflow JSON
- **WHEN** building payload for a pipeline step
- **THEN** workflow JSON from step is included

#### Scenario: Substitute run prompt
- **WHEN** step has needs_run_prompt = true
- **THEN** prompt from pipeline_run.variables is included

#### Scenario: Include parent image path
- **WHEN** step has needs_parent_image_path = true
- **THEN** parent candidate image_path is included

#### Scenario: Include all run variables
- **WHEN** step has needs_run_variables = true
- **THEN** all variables from pipeline_run are included

#### Scenario: Set output folder
- **WHEN** building payload
- **THEN** output folder uses run.target_folder + step name

#### Scenario: Base generation no parent
- **WHEN** building payload for base generation (no parent)
- **THEN** only run variables are included, no parent path

### Requirement: SelectNextJob Command
The system SHALL provide a GLCommand for job selection.

#### Scenario: Successful job selection
- **WHEN** SelectNextJob is executed
- **THEN** returns success with parent, step, and mode

#### Scenario: Command requires
- **WHEN** SelectNextJob declares requirements
- **THEN** it requires no input parameters

#### Scenario: Command returns
- **WHEN** SelectNextJob executes
- **THEN** it returns parent_candidate, next_step, mode

### Requirement: BuildJobPayload Command
The system SHALL provide a GLCommand for payload construction.

#### Scenario: Successful payload build
- **WHEN** BuildJobPayload is executed with valid inputs
- **THEN** returns success with job_payload

#### Scenario: Command requires
- **WHEN** BuildJobPayload declares requirements
- **THEN** it requires pipeline_step, pipeline_run, and optionally parent_candidate

#### Scenario: Command returns
- **WHEN** BuildJobPayload executes
- **THEN** it returns job_payload hash

### Requirement: Job Orchestration Pack
The system SHALL organize job orchestration logic in a dedicated pack.

#### Scenario: Pack configuration exists
- **WHEN** Packwerk is run
- **THEN** job_orchestration pack is recognized

#### Scenario: Pack dependencies
- **WHEN** checking pack dependencies
- **THEN** job_orchestration depends on pipeline pack

#### Scenario: Pack validation passes
- **WHEN** running bin/packwerk validate
- **THEN** no errors are reported for job_orchestration pack

### Requirement: Deterministic Selection for Testing
The system SHALL support deterministic random selection for testing.

#### Scenario: Seeded random
- **WHEN** random seed is set in tests
- **THEN** raffle selection is reproducible

#### Scenario: Distribution testing
- **WHEN** running raffle 1000 times
- **THEN** distribution matches ELO weight ratios within margin

### Requirement: Edge Case Handling
The system SHALL handle edge cases gracefully.

#### Scenario: No pipelines exist
- **WHEN** no pipelines are in database
- **THEN** SelectNextJob returns :no_work mode

#### Scenario: Pipeline with no runs
- **WHEN** pipeline exists but has no pipeline_runs
- **THEN** SelectNextJob returns :no_work mode

#### Scenario: All candidates rejected
- **WHEN** all candidates have status = 'rejected'
- **THEN** deficit mode may trigger base generation

#### Scenario: Empty ELO scores
- **WHEN** all candidates have ELO = 0
- **THEN** equal probability selection (prevent division by zero)
