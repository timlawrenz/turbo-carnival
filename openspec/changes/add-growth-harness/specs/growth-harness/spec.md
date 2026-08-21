# Growth Harness Spec

## ADDED Requirements

### Requirement: Follower Goal Tracking

The system SHALL maintain a per-persona growth goal with a target follower
count and deadline, and SHALL expose current status (active/paused) and the
goal's lifecycle.

#### Scenario: Goal exists with defaults
- **WHEN** a goal is created for a persona
- **THEN** it defaults to 1,000 target followers and a 365-day deadline from
  creation, with status `active`

#### Scenario: Only one active goal per persona
- **WHEN** a goal is created for a persona that already has an active goal
- **THEN** a new goal may be created but the harness acts on the most recent
  active goal

### Requirement: Follower Snapshot Collection

The system SHALL record follower count snapshots over time, tagged with the
taken-at timestamp, so growth rate can be measured.

#### Scenario: Snapshot captured
- **WHEN** the metrics collector runs and Instagram returns a follower count
- **THEN** a snapshot row is stored with the count and timestamp

#### Scenario: API failure is non-fatal
- **WHEN** the Instagram API fails or credentials are missing
- **THEN** the collector logs a warning and the harness continues without a
  snapshot

### Requirement: Cadence Maintenance

The system SHALL top up the scheduled-post queue so that scheduled and draft
posts cover the goal's target cadence over the lookahead window.

#### Scenario: Queue behind cadence
- **WHEN** the cadence engine runs and fewer posts are scheduled than the
  cadence target requires
- **THEN** it creates new scheduled posts through the existing
  PostAutomation::AutoCreateNextPost command until the target is met or no
  unposted photos remain

#### Scenario: No photos available
- **WHEN** the cadence engine runs and no unposted photos remain
- **THEN** it logs the shortfall and does not raise

### Requirement: Strategy Review Loop

The system SHALL periodically evaluate measured follower growth against the
trajectory required to hit the goal, and SHALL adjust strategy knobs when the
pace diverges, recording each adjustment as a decision.

#### Scenario: Behind trajectory
- **WHEN** measured growth rate is below the required rate
- **THEN** the brain escalates effort (cadence frequency and/or hashtag
  count) and records a `Growth::Decision` with rationale

#### Scenario: Ahead of trajectory
- **WHEN** measured growth rate is well above the required rate
- **THEN** the brain may cut cadence back to conserve inventory and records
  the decision

#### Scenario: Review interval respected
- **WHEN** the review runs before the configured interval has elapsed
- **THEN** it skips decision-making and reports when the next review is due

### Requirement: Reviewable Decision Log

The system SHALL record every strategy change in a decision log with enough
context (snapshot, rationale, from/to values) for a human to audit and revert.

#### Scenario: Decision recorded
- **WHEN** the brain changes any strategy knob
- **THEN** a decision row stores the goal, snapshot, rationale, and the
  before/after values

### Requirement: Growth Dashboard

The system SHALL expose a dashboard page showing the goal, latest follower
count, trajectory status (on/behind), recent snapshots, and recent decisions.

#### Scenario: Dashboard renders
- **WHEN** a user visits `/growth`
- **THEN** goal status, last snapshot, and recent decisions are displayed