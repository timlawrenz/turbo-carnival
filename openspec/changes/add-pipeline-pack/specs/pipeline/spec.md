## ADDED Requirements

### Requirement: Pipeline Configuration
The system SHALL provide a `Pipeline` model to store reusable pipeline configurations that can be executed multiple times.

#### Scenario: Create pipeline configuration
- **WHEN** a user creates a new pipeline with a name
- **THEN** the pipeline is persisted and can be referenced by pipeline steps

#### Scenario: Pipeline with multiple steps
- **WHEN** a pipeline is created with associated steps
- **THEN** the steps are ordered and retrievable in sequence

### Requirement: Pipeline Steps
The system SHALL provide a `PipelineStep` model to define ordered stages within a pipeline, each with its own ComfyUI workflow configuration.

#### Scenario: Create ordered steps
- **WHEN** pipeline steps are created with order values 1, 2, 3
- **THEN** steps are retrieved in ascending order

#### Scenario: Store ComfyUI workflow
- **WHEN** a pipeline step is created with workflow JSON
- **THEN** the workflow JSON is stored and retrievable for job execution

#### Scenario: Unique step ordering
- **WHEN** attempting to create two steps with the same order in one pipeline
- **THEN** validation fails with uniqueness error

#### Scenario: Steps belong to pipeline
- **WHEN** retrieving steps for a specific pipeline
- **THEN** only steps belonging to that pipeline are returned

### Requirement: Image Candidate Tree Structure
The system SHALL provide an `ImageCandidate` model that represents nodes in a tree, where each candidate may have a parent candidate and multiple children.

#### Scenario: Root candidate (base generation)
- **WHEN** creating an image candidate with no parent
- **THEN** `parent_id` is null and candidate represents a base generation

#### Scenario: Child candidate
- **WHEN** creating an image candidate with a parent reference
- **THEN** the candidate is linked to its parent in the tree structure

#### Scenario: Multiple children
- **WHEN** multiple image candidates reference the same parent
- **THEN** all are linked as children of that parent

#### Scenario: Tree traversal
- **WHEN** accessing a candidate's children
- **THEN** all direct child candidates are returned

### Requirement: Pipeline Step Association
The system SHALL associate each `ImageCandidate` with a specific `PipelineStep` to track which stage of the pipeline produced it.

#### Scenario: Candidate at specific step
- **WHEN** an image candidate is created for a pipeline step
- **THEN** the candidate is associated with that step

#### Scenario: Retrieve candidates by step
- **WHEN** querying candidates for a specific pipeline step
- **THEN** all candidates for that step are returned

### Requirement: ELO Score Tracking
The system SHALL track an ELO score for each `ImageCandidate` to represent its relative quality ranking.

#### Scenario: Default ELO score
- **WHEN** a new image candidate is created
- **THEN** it is initialized with an ELO score of 1000

#### Scenario: ELO score updates
- **WHEN** an image candidate's ELO score is updated based on voting
- **THEN** the new score is persisted

### Requirement: Image Candidate Status State Machine
The system SHALL manage `ImageCandidate` status using a state machine with states `active` and `rejected`.

#### Scenario: Default active status
- **WHEN** a new image candidate is created
- **THEN** its status is `active`

#### Scenario: Reject candidate
- **WHEN** a candidate is transitioned to `rejected` status
- **THEN** the status is updated and persisted

#### Scenario: Rejected is terminal
- **WHEN** a candidate is in `rejected` status
- **THEN** no transitions back to `active` are permitted

### Requirement: Child Count Tracking
The system SHALL track the number of direct children for each `ImageCandidate` using a cached counter.

#### Scenario: Initial child count
- **WHEN** a new image candidate is created
- **THEN** `child_count` is initialized to 0

#### Scenario: Increment child count
- **WHEN** a child candidate is created with a parent reference
- **THEN** the parent's `child_count` is incremented by 1

#### Scenario: Decrement child count
- **WHEN** a child candidate is destroyed
- **THEN** the parent's `child_count` is decremented by 1

### Requirement: Image Path Storage
The system SHALL store the filesystem path to each generated image in the `ImageCandidate` model.

#### Scenario: Store image path
- **WHEN** an image is generated and saved
- **THEN** the path is stored in `image_path` attribute

#### Scenario: Retrieve image
- **WHEN** accessing an image candidate's `image_path`
- **THEN** the path can be used to locate the image file

### Requirement: Pack Boundary Enforcement
The system SHALL organize the `Pipeline`, `PipelineStep`, and `ImageCandidate` models within a dedicated `packs/pipeline` pack using Packwerk.

#### Scenario: Pack configuration exists
- **WHEN** Packwerk is run
- **THEN** the pipeline pack is recognized with valid configuration

#### Scenario: Pack validation passes
- **WHEN** running `bin/packwerk validate`
- **THEN** no errors are reported for the pipeline pack

#### Scenario: Pack privacy boundaries
- **WHEN** running `bin/packwerk check`
- **THEN** no violations of pack dependencies are detected

### Requirement: Database Indexes for Performance
The system SHALL include database indexes optimized for job selection queries and tree traversal.

#### Scenario: Pipeline step lookup
- **WHEN** querying pipeline steps by pipeline_id
- **THEN** the query uses an index on `pipeline_id`

#### Scenario: Child lookup by parent
- **WHEN** querying children of a specific parent candidate
- **THEN** the query uses an index on `parent_id`

#### Scenario: Job selection query
- **WHEN** filtering candidates by status and child_count
- **THEN** the query uses a composite index on `(status, child_count)`

#### Scenario: ELO raffle selection
- **WHEN** selecting candidates weighted by ELO score
- **THEN** the query uses an index on `elo_score`

### Requirement: Model Validations
The system SHALL validate all model attributes to ensure data integrity.

#### Scenario: Pipeline name required
- **WHEN** creating a pipeline without a name
- **THEN** validation fails

#### Scenario: Step order required
- **WHEN** creating a pipeline step without an order value
- **THEN** validation fails

#### Scenario: Step order positive integer
- **WHEN** creating a pipeline step with order value 0 or negative
- **THEN** validation fails

#### Scenario: ComfyUI workflow required
- **WHEN** creating a pipeline step without workflow JSON
- **THEN** validation fails

#### Scenario: Valid status values
- **WHEN** attempting to set status to a value other than 'active' or 'rejected'
- **THEN** validation fails

#### Scenario: Non-negative child count
- **WHEN** attempting to set child_count to a negative value
- **THEN** validation fails
