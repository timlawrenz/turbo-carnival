## MODIFIED Requirements

### Requirement: The system SHALL provide configuration for job orchestration parameters.
The system SHALL provide configuration for job orchestration parameters to control breadth-first generation.

#### Scenario: Max children configuration
- **WHEN** accessing the max children configuration
- **THEN** it returns the configured N value (default 2)

#### Scenario: Target leaf nodes configuration
- **WHEN** accessing the target leaf nodes configuration
- **THEN** it returns the configured T value (default 10)

#### Scenario: Environment override
- **WHEN** MAX_CHILDREN_PER_NODE environment variable is set to 3
- **THEN** configuration returns 3

## MODIFIED Requirements

### Requirement: The system SHALL select the next job using a strict breadth-first strategy.
The system SHALL fill each pipeline step to N active candidates before advancing to the next step, where N is configured by `MAX_CHILDREN_PER_NODE`.

#### Scenario: Step not filled
- **WHEN** Step 1 has 1 active candidate and N=2
- **THEN** generate another Step 1 candidate before advancing

#### Scenario: Step filled, next step empty
- **WHEN** Step 1 has N active candidates and Step 2 has 0 candidates
- **THEN** generate a Step 2 candidate from Step 1 parent

#### Scenario: All steps filled to N
- **WHEN** all steps have N active candidates
- **THEN** return :no_work mode

#### Scenario: Candidate rejected triggers refill
- **WHEN** Step 2 had N candidates but one is rejected leaving N-1
- **THEN** generate another Step 2 candidate to maintain N active candidates

#### Scenario: Multiple pipelines
- **WHEN** Pipeline A has incomplete steps and Pipeline B has incomplete steps
- **THEN** fill Pipeline A's earliest incomplete step first

## REMOVED Requirements

### Requirement: The system SHALL prioritize candidates from higher-order pipeline steps.
**Reason**: Replacing "triage-right" (depth-first) strategy with strict breadth-first strategy.
**Migration**: Breadth-first fills all steps to N before going deeper, so explicit rightmost prioritization is no longer needed.
