## ADDED Requirements

### Requirement: Pipeline Run Step Approval
The system SHALL track approval state for each step within each pipeline run independently.

#### Scenario: New run has first step auto-approved
- **GIVEN** a user creates a new PipelineRun
- **WHEN** the run is created
- **THEN** the first step is automatically approved
- **AND** all other steps are unapproved

#### Scenario: Per-run approval isolation
- **GIVEN** Run A and Run B both use the same Pipeline
- **WHEN** Run A's Step 2 is approved
- **THEN** Run B's Step 2 remains unapproved
- **AND** the approval states are independent

#### Scenario: Approval is one-way
- **GIVEN** a step has been approved
- **WHEN** a user attempts to un-approve it
- **THEN** the system prevents the action
- **AND** shows message "Approvals cannot be reverted. Create new run for different configuration."

### Requirement: Top-K ELO Filtering on Approval
The system SHALL filter candidates to the top-K highest ELO scores when a step is approved.

#### Scenario: Global top-K filtering
- **GIVEN** Step 2 has 6 candidates from 2 parents:
  - Parent A children: A1 (ELO 1200), A2 (1100), A3 (1000)
  - Parent B children: B1 (ELO 1150), B2 (1050), B3 (950)
- **WHEN** user approves Step 2 with K=3
- **THEN** only A1, B1, A2 are marked as "approved to advance"
- **AND** A3, B2, B3 cannot become parents for Step 3

#### Scenario: K greater than candidate count
- **GIVEN** Step 2 has 2 candidates
- **WHEN** user approves with K=3
- **THEN** both candidates are approved to advance
- **AND** no error is shown (K is a maximum, not a requirement)

#### Scenario: K equals zero
- **GIVEN** user attempts to approve with K=0
- **THEN** system shows error "K must be at least 1"
- **AND** step remains unapproved

#### Scenario: Tied ELO scores
- **GIVEN** Step 2 has 5 candidates with ELO: 1200, 1200, 1150, 1100, 1000
- **WHEN** user approves with K=3
- **THEN** both 1200 ELO candidates are approved (tie at top)
- **AND** 1150 is also approved (total = 3)
- **AND** candidates with ELO 1100 and 1000 are not approved

### Requirement: Job Selection Respects Approval Gates
The system SHALL only select candidates from approved steps as parents for the next step.

#### Scenario: Unapproved step blocks progression
- **GIVEN** Run A has Step 1 approved with 3 candidates
- **AND** Step 2 is unapproved
- **WHEN** SelectNextJob is called for Run A
- **THEN** Step 2 is selected for generation (no parents needed)
- **AND** Step 3 is not selected (Step 2 is unapproved)

#### Scenario: Approved step enables progression
- **GIVEN** Run A has Step 2 approved with 3 candidates (top-K filtered)
- **AND** Step 3 is unapproved
- **WHEN** SelectNextJob is called for Run A
- **THEN** the 3 approved Step 2 candidates can become parents
- **AND** Step 3 jobs can be generated

#### Scenario: Only top-K candidates become parents
- **GIVEN** Step 2 has 5 candidates total
- **AND** Step 2 was approved with K=3
- **AND** 3 candidates are marked as "approved to advance"
- **WHEN** SelectNextJob selects parents from Step 2
- **THEN** only the 3 approved candidates are eligible
- **AND** the other 2 candidates are skipped

#### Scenario: Run stalls at unapproved step
- **GIVEN** Run A has all steps unapproved except Step 1
- **AND** Step 1 has 3 candidates
- **WHEN** SelectNextJob is called for Run A
- **THEN** mode is :no_work
- **AND** message is "Run #A waiting for Step 1 approval"

### Requirement: Approval UI with Top-K Preview
The system SHALL provide a UI to preview top-K candidates before approving a step.

#### Scenario: Show approval preview
- **GIVEN** user views Run A's dashboard
- **AND** Step 2 has 5 candidates
- **WHEN** user clicks "Preview Approval" for Step 2
- **THEN** candidates are displayed sorted by ELO descending
- **AND** top 3 are visually highlighted as "Will advance"
- **AND** bottom 2 are shown as "Will not advance"

#### Scenario: Configurable K in preview
- **GIVEN** user is viewing approval preview for Step 2
- **WHEN** user changes K from 3 to 5
- **THEN** preview updates to highlight top 5
- **AND** "Approve with K=5" button is enabled

#### Scenario: Warning for low vote counts
- **GIVEN** Step 2 candidates have fewer than 5 votes each
- **WHEN** user views approval preview
- **THEN** warning shown: "⚠️ Low vote counts. Rankings may not be reliable. Recommend voting more before approval."
- **AND** user can still approve (warning, not error)

#### Scenario: Approve action is final
- **GIVEN** user views approval preview
- **WHEN** user clicks "Approve with K=3"
- **THEN** PipelineRunStep is updated with approved=true, top_k_count=3
- **AND** top 3 candidates are marked as eligible parents
- **AND** approval cannot be undone
- **AND** user is redirected to run dashboard

### Requirement: Dashboard Shows Approval Status
The system SHALL display approval status for each step in the run dashboard.

#### Scenario: Visual status indicators
- **GIVEN** a user views Run A's dashboard
- **THEN** each step shows its status:
  - ✅ "Approved (3/5 advancing)" - approved with some filtered out
  - ✅ "Approved (all advancing)" - approved with K >= candidate count
  - ⏸️ "Awaiting Approval (5 candidates ready)" - has candidates, needs approval
  - 🔒 "Blocked (Step 2 unapproved)" - cannot generate until previous approved
  - 🔄 "Generating (2/3 candidates)" - still generating, not ready to approve

#### Scenario: Approve button availability
- **GIVEN** Run A's Step 2 has 3 candidates
- **AND** Step 2 is unapproved
- **WHEN** user views run dashboard
- **THEN** "Approve Step 2" button is enabled
- **AND** clicking opens approval preview modal

#### Scenario: Already approved steps
- **GIVEN** Run A's Step 2 is already approved
- **WHEN** user views run dashboard
- **THEN** "Approve Step 2" button is replaced with badge "✅ Approved 2 hours ago"
- **AND** badge shows how many candidates advanced

### Requirement: Configuration for N and K
The system SHALL allow independent configuration of N (generate count) and K (advance count).

#### Scenario: Global defaults
- **GIVEN** no custom configuration
- **WHEN** system generates candidates
- **THEN** N = JobOrchestrationConfig.max_children_per_node (default: 3)
- **AND** K = default_top_k (default: 3)

#### Scenario: Custom N per run
- **GIVEN** user creates run with max_children_per_node=5
- **WHEN** jobs are generated
- **THEN** each parent gets N=5 children

#### Scenario: Custom K per approval
- **GIVEN** user approves Step 2
- **WHEN** user sets K=2 in approval UI
- **THEN** only top 2 candidates can advance
- **AND** PipelineRunStep.top_k_count is set to 2

#### Scenario: N and K are independent
- **GIVEN** N=5 (generate 5 per parent)
- **AND** K=2 (advance top 2)
- **WHEN** Step 2 has 10 candidates from 2 parents
- **THEN** only top 2 globally can become parents for Step 3
- **AND** 8 candidates are filtered out

### Requirement: Migration for Existing Runs
The system SHALL auto-approve all steps for existing runs during migration.

#### Scenario: Backfill existing runs
- **GIVEN** database has 10 active PipelineRuns before migration
- **WHEN** migration runs
- **THEN** PipelineRunStep records are created for all run-step combinations
- **AND** all steps for existing runs are marked approved=true
- **AND** top_k_count is set to N (no filtering for existing runs)

#### Scenario: New runs after migration
- **GIVEN** migration has completed
- **WHEN** user creates a new run
- **THEN** only Step 1 is auto-approved
- **AND** all other steps require manual approval

## REMOVED Requirements

None. This is purely additive functionality.

## CHANGED Requirements

### CHANGED: SelectNextJob - Parent Eligibility
The `find_eligible_parents` method SHALL be modified to filter by approval status.

**Before:**
- All active candidates with child_count < N are eligible

**After:**
- All active candidates with child_count < N
- **AND** whose step is approved
- **AND** who are in top-K for their step
- Are eligible
