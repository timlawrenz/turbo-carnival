## ADDED Requirements

### Requirement: The system SHALL select the next job using a per-run strict breadth-first strategy.
The system SHALL select one pipeline run to work on and fill that run's steps to N active candidates before advancing to the next step within that run.

#### Scenario: Single run with incomplete step
- **WHEN** Run A has Step 1 with 2 candidates and Step 2 with 1 candidate (N=2)
- **THEN** generate another Step 2 candidate for Run A

#### Scenario: Multiple runs with different completion levels
- **WHEN** Run A has all steps filled and Run B has Step 3 with 1 candidate
- **THEN** select Run B and generate a Step 3 candidate

#### Scenario: Run selection strategy
- **WHEN** multiple runs need work
- **THEN** use round-robin or priority-based selection to pick which run to work on

#### Scenario: Per-run candidate counting
- **WHEN** Run A has 1 Step 2 candidate and Run B has 2 Step 2 candidates
- **THEN** generate a Step 2 candidate for Run A (not counted globally)

#### Scenario: Run completion
- **WHEN** a run has N candidates at all steps
- **THEN** mark that run as eligible for completion and move to next run

## ADDED Requirements
- **WHEN** all runs are marked as completed
- **THEN** return :no_work mode

## ADDED Requirements

### Requirement: The system SHALL provide a per-run voting interface.
Users SHALL be able to vote on candidates within a specific pipeline run using nested routes.

#### Scenario: Access voting for specific run
- **WHEN** user navigates to `/runs/14/vote`
- **THEN** show voting interface for Run 14 only

#### Scenario: Filtered voting pairs
- **WHEN** viewing `/runs/14/vote`
- **THEN** show only unvoted pairs from Run 14's candidates

#### Scenario: Run progress display
- **WHEN** viewing a run's voting interface
- **THEN** display completion status (e.g., "Step 1: 2/2, Step 2: 1/2")

#### Scenario: Reject candidate within run context
- **WHEN** user rejects candidate via `/runs/14/vote/reject/123`
- **THEN** reject candidate 123 and stay in Run 14's voting context

### Requirement: The system SHALL provide a per-run gallery interface.
Users SHALL be able to browse and curate candidates within a specific pipeline run using nested routes.

#### Scenario: Access gallery for specific run
- **WHEN** user navigates to `/runs/14/gallery`
- **THEN** show gallery for Run 14 only

#### Scenario: Run filtering in gallery
- **WHEN** viewing `/runs/14/gallery?step=2`
- **THEN** show only Step 2 candidates from Run 14

#### Scenario: Per-run step completion
- **WHEN** viewing gallery for a run
- **THEN** display how many candidates exist per step for that run

#### Scenario: Reject candidate within run context
- **WHEN** user rejects candidate via `/runs/14/candidates/123/reject`
- **THEN** reject candidate 123 and stay in Run 14's gallery

### Requirement: The system SHALL provide a run dashboard.
Users SHALL be able to view all pipeline runs and their completion status.

#### Scenario: List all runs
- **WHEN** accessing run dashboard
- **THEN** show all pipeline runs with status (pending/running/completed)

#### Scenario: Per-run statistics
- **WHEN** viewing run dashboard
- **THEN** show completion percentage and candidate counts per run

#### Scenario: Manual run completion
- **WHEN** user marks a run as complete
- **THEN** change run status to 'completed' and exclude from active job selection
