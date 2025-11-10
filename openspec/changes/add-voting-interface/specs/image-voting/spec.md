## ADDED Requirements

### Requirement: Voting Interface Display
The system SHALL provide a voting interface that displays two ImageCandidates side-by-side for comparison.

#### Scenario: Initial load shows rightmost candidates
- **WHEN** a user visits the voting interface
- **THEN** the system displays two unvoted ImageCandidates from the rightmost PipelineStep with available pairs

#### Scenario: No pairs available
- **WHEN** a user visits the voting interface and no unvoted pairs exist
- **THEN** the system displays a message indicating all images have been reviewed

#### Scenario: Images display with metadata
- **WHEN** the voting interface renders a pair
- **THEN** each image displays its PipelineStep name and generation timestamp

### Requirement: Vote Recording
The system SHALL allow users to vote for a preferred ImageCandidate in a comparison and update both candidates' ELO scores.

#### Scenario: User votes for left image
- **WHEN** a user clicks the left image or presses the left arrow key
- **THEN** the left ImageCandidate's ELO score increases and the right ImageCandidate's ELO score decreases based on ELO formula
- **AND** the next pair is immediately displayed

#### Scenario: User votes for right image
- **WHEN** a user clicks the right image or presses the right arrow key
- **THEN** the right ImageCandidate's ELO score increases and the left ImageCandidate's ELO score decreases based on ELO formula
- **AND** the next pair is immediately displayed

#### Scenario: Optimistic UI update
- **WHEN** a user votes on a pair
- **THEN** the next pair is shown immediately without waiting for backend response
- **AND** backend ELO calculation occurs asynchronously

### Requirement: ELO Calculation
The system SHALL calculate ELO score changes using standard ELO algorithm with K-factor of 32.

#### Scenario: Evenly matched candidates
- **GIVEN** ImageCandidate A has ELO 1000 and ImageCandidate B has ELO 1000
- **WHEN** user votes for A
- **THEN** A's new ELO is 1016 and B's new ELO is 984

#### Scenario: Underdog wins
- **GIVEN** ImageCandidate A has ELO 800 and ImageCandidate B has ELO 1200
- **WHEN** user votes for A
- **THEN** A gains more points than if equally matched and B loses more points

#### Scenario: Favorite wins
- **GIVEN** ImageCandidate A has ELO 1200 and ImageCandidate B has ELO 800
- **WHEN** user votes for A
- **THEN** A gains fewer points than if equally matched and B loses fewer points

### Requirement: Branch Rejection (Kill)
The system SHALL allow users to mark an ImageCandidate as rejected, preventing it from being used as a parent in future generation jobs.

#### Scenario: User rejects an image
- **WHEN** a user clicks "Kill" on an ImageCandidate or presses the K key
- **THEN** the ImageCandidate's status is set to 'rejected'
- **AND** the image is excluded from future parent selection in the job algorithm

#### Scenario: Rejected image stops branch growth
- **GIVEN** an ImageCandidate has status 'rejected'
- **WHEN** the job algorithm queries for eligible parents
- **THEN** the rejected ImageCandidate is not included in the results

### Requirement: Kill-Left Navigation
The system SHALL provide a workflow to navigate from a rejected image to its parent to identify root causes of poor image quality.

#### Scenario: Navigate to parent after kill
- **WHEN** a user kills an ImageCandidate that has a parent
- **THEN** the system displays the parent ImageCandidate alongside one of its siblings for comparison
- **AND** the user can vote or kill at the parent level

#### Scenario: Navigate to parent of base image
- **WHEN** a user kills an ImageCandidate with parent_id null
- **THEN** no navigation occurs (base image is the root)
- **AND** the next unvoted pair is displayed

#### Scenario: Cascading kill investigation
- **GIVEN** a user killed a "Final Upscale" image and navigated to its "Hand Fix" parent
- **WHEN** the user kills the "Hand Fix" parent
- **THEN** the system navigates to the "Face Fix" grandparent with a sibling comparison

### Requirement: Keyboard Shortcuts
The system SHALL support keyboard shortcuts for rapid voting without mouse interaction.

#### Scenario: Left arrow votes left
- **WHEN** a user presses the left arrow key
- **THEN** the left ImageCandidate is voted as preferred

#### Scenario: Right arrow votes right
- **WHEN** a user presses the right arrow key
- **THEN** the right ImageCandidate is voted as preferred

#### Scenario: K key kills
- **WHEN** a user presses the K key
- **THEN** the currently focused ImageCandidate is marked as rejected
- **AND** kill-left navigation is triggered

#### Scenario: N key skips
- **WHEN** a user presses the N key
- **THEN** the current pair is skipped without voting
- **AND** the next unvoted pair is displayed

### Requirement: Triage-Right Strategy
The system SHALL prioritize showing ImageCandidates from rightmost (highest order) PipelineSteps first.

#### Scenario: Multiple steps have unvoted pairs
- **GIVEN** unvoted pairs exist in "Base Generation" (order 1), "Hand Fix" (order 3), and "Final Upscale" (order 4)
- **WHEN** the voting interface loads
- **THEN** a pair from "Final Upscale" is shown first

#### Scenario: Rightmost exhausted
- **GIVEN** all pairs in "Final Upscale" (order 4) have been voted on
- **AND** unvoted pairs exist in "Hand Fix" (order 3)
- **WHEN** the voting interface loads the next pair
- **THEN** a pair from "Hand Fix" is shown

### Requirement: Responsive UI
The system SHALL provide responsive layout for voting on mobile and desktop devices.

#### Scenario: Desktop layout
- **WHEN** viewing on a screen wider than 768px
- **THEN** images are displayed side-by-side in two columns

#### Scenario: Mobile layout
- **WHEN** viewing on a screen narrower than 768px
- **THEN** images are stacked vertically for easier comparison on small screens


