# post-creation Delta

## MODIFIED Requirements

### Requirement: Photo Selection Interface
The system SHALL extend existing photo browsing to support automated suggestion workflow.

#### Scenario: Navigate to automated suggestion
- **WHEN** user clicks "Get Next Suggested Post" button
- **THEN** system calls ContentStrategy::SelectNextPost command
- **AND** redirects to post creation form with suggested photo
- **AND** displays strategy name used for selection

### Requirement: Post Creation Form
The system SHALL extend existing form to support strategy-selected photos and metadata.

#### Scenario: Display strategy metadata
- **WHEN** viewing post form for strategy-suggested photo
- **THEN** show which strategy selected this photo
- **AND** show cluster theme and rationale
- **AND** show calculated optimal posting time
- **AND** pre-fill hashtags from strategy

#### Scenario: Schedule at optimal time
- **WHEN** user selects "Use Optimal Time" option
- **THEN** pre-fill scheduled_at with calculated optimal time
- **AND** show explanation (e.g., "5-8am peak engagement window")
- **AND** allow user to override if needed

## ADDED Requirements

### Requirement: Automated Content Suggestion
The system SHALL provide intelligent photo suggestions based on posting strategy and variety rules.

#### Scenario: Suggest next post via strategy
- **WHEN** user clicks "Get Next Suggested Post" button
- **THEN** system selects next photo using active strategy for persona
- **AND** applies content variety enforcement rules
- **AND** calculates optimal posting time
- **AND** generates appropriate hashtags
- **AND** redirects to post creation form with all data pre-filled

#### Scenario: Handle no available photos
- **WHEN** strategy cannot find eligible photo (all posted or no clusters)
- **THEN** show error message explaining the issue
- **AND** suggest actions (upload more photos, reset posting history)
- **AND** remain on posts index page

#### Scenario: Show active strategy
- **WHEN** viewing posts index page
- **THEN** display persona's active posting strategy name
- **AND** show last strategy-selected post date
- **AND** show posts remaining in current rotation/week

### Requirement: Strategy Selection and Configuration
The system SHALL allow users to select and configure posting strategies per persona.

#### Scenario: View available strategies
- **WHEN** user accesses strategy configuration
- **THEN** list all available strategies (Theme of Week, Thematic Rotation)
- **AND** show description of each strategy's approach
- **AND** show current active strategy for persona

#### Scenario: Switch posting strategy
- **WHEN** user selects a different strategy
- **THEN** update persona's active strategy
- **AND** reset strategy state
- **AND** show confirmation message

#### Scenario: Configure strategy parameters
- **WHEN** user edits strategy configuration
- **THEN** show current values from config
- **AND** allow editing frequency, timing, variety rules
- **AND** validate values before saving
- **AND** persist to strategy_config JSONB

### Requirement: Posting History Tracking
The system SHALL track which strategy selected each photo for audit and analysis.

#### Scenario: Record strategy decision
- **WHEN** post is created from strategy suggestion
- **THEN** store strategy_name in post record
- **AND** store cluster_id in post record
- **AND** store optimal_time_calculated in post record
- **AND** create history record with full decision context

#### Scenario: View posting history
- **WHEN** user views persona posting history
- **THEN** show chronological list of posted content
- **AND** display which strategy selected each post
- **AND** display cluster used for each post
- **AND** display optimal time vs. actual scheduled time

### Requirement: Strategy State Persistence
The system SHALL persist strategy state across sessions to maintain consistent posting patterns.

#### Scenario: Persist theme of week state
- **WHEN** using Theme of Week strategy
- **THEN** store current week number
- **AND** store current cluster_id for week
- **AND** retrieve state on next suggestion request
- **AND** advance week when cluster exhausted

#### Scenario: Persist rotation state
- **WHEN** using Thematic Rotation strategy
- **THEN** store current rotation index
- **AND** retrieve state on next suggestion request
- **AND** wrap around when reaching end of cluster list
