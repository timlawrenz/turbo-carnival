# post-creation Specification Delta

## ADDED Requirements

### Requirement: LLM Campaign Creation API
The system SHALL provide an API endpoint for creating multi-post content campaigns from LLM-generated strategies.

#### Scenario: Create campaign via API
- **WHEN** LLM sends POST request to `/api/campaigns` with persona_id and post specifications
- **THEN** create GapAnalysis record with campaign metadata
- **AND** create ContentSuggestion for each post specification
- **AND** create draft Scheduling::Post for each specification
- **AND** return JSON with IDs of created records

#### Scenario: Campaign with missing persona
- **WHEN** API request includes non-existent persona_id
- **THEN** return 422 status code
- **AND** include error message "Persona not found"

#### Scenario: Campaign with invalid dates
- **WHEN** API request includes past scheduled_at date
- **THEN** return 422 status code
- **AND** include error message identifying which post has invalid date

### Requirement: Image Promise Posts
The system SHALL allow creating Scheduling::Post records without photos when linked to ContentSuggestions.

#### Scenario: Create post without photo
- **WHEN** creating Scheduling::Post with content_suggestion_id but no photo_id
- **THEN** save record with status 'draft'
- **AND** allow photo_id to be NULL

#### Scenario: Transition to awaiting state
- **WHEN** PipelineRun is created and linked to draft post
- **THEN** update post status to 'awaiting_image'
- **AND** store pipeline_run_id reference

#### Scenario: Auto-link completed image
- **WHEN** PipelineRun completes with winner selected
- **THEN** find all Scheduling::Posts with matching pipeline_run_id
- **AND** update posts with winner's photo_id
- **AND** transition posts to 'ready' status

#### Scenario: Prevent posting without photo
- **WHEN** attempting to schedule post in 'draft' or 'awaiting_image' status
- **THEN** validation fails
- **AND** error indicates photo is required for scheduling

## MODIFIED Requirements

### Requirement: Post Creation Form
**Previous:** The system SHALL provide a form for creating Instagram posts with caption and scheduling options.

**Modified:** The system SHALL provide a form for creating Instagram posts with caption and scheduling options, AND support creating posts from LLM-generated ContentSuggestions.

#### Scenario: Create post from ContentSuggestion
- **WHEN** user clicks "Create Draft Post" from ContentSuggestion view
- **THEN** create Scheduling::Post with pre-filled caption and hashtags from suggestion metadata
- **AND** set scheduled_at from suggestion metadata
- **AND** link post to content_suggestion
- **AND** leave photo_id NULL until image generated

#### Scenario: Generate image for suggestion
- **WHEN** user clicks "Generate Image" from ContentSuggestion with linked post
- **THEN** create PipelineRun with suggestion's prompt
- **AND** link PipelineRun to post via pipeline_run_id
- **AND** update post status to 'awaiting_image'
