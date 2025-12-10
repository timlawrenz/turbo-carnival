## MODIFIED Requirements

### Requirement: Photo Selection Interface
The system SHALL provide a web interface for browsing and selecting unposted photos for post creation.

#### Scenario: Browse unposted photos
- **WHEN** user navigates to post creation
- **THEN** display a grid of unposted photos
- **AND** show photo preview, persona, and content pillar information

#### Scenario: Filter by persona
- **WHEN** user selects a persona filter
- **THEN** show only photos for that persona
- **AND** maintain unposted filter status

#### Scenario: Filter by content pillar
- **WHEN** user selects a content pillar filter
- **THEN** show only photos in that pillar
- **AND** display pillar name and description

#### Scenario: Select photo for posting
- **WHEN** user clicks "Create Post" on a photo
- **THEN** navigate to post creation form with photo pre-selected
- **AND** display photo preview with metadata

### Requirement: Post Creation Form
The system SHALL provide a form for creating Instagram posts with caption and scheduling options.

#### Scenario: Display post form with photo
- **WHEN** user accesses post creation form with selected photo
- **THEN** show photo preview with content pillar and persona info
- **AND** show empty caption textarea
- **AND** show empty hashtags input
- **AND** show scheduling options

#### Scenario: Manual caption entry
- **WHEN** user types in caption textarea
- **THEN** show character count
- **AND** validate maximum length
- **AND** enable submit button when valid

#### Scenario: Manual hashtag entry
- **WHEN** user enters hashtags
- **THEN** validate hashtag format
- **AND** show count of hashtags
- **AND** warn if exceeding recommended limit

#### Scenario: Schedule for later
- **WHEN** user selects "Schedule" option
- **THEN** show datetime picker
- **AND** default to next optimal posting time
- **AND** create draft post with scheduled_at timestamp

#### Scenario: Post immediately
- **WHEN** user selects "Post Now" option
- **THEN** execute SchedulePost command chain
- **AND** show posting progress
- **AND** redirect to success page with Instagram link

### Requirement: AI Caption Suggestion
The system SHALL generate caption suggestions using Gemma3:27b model with persona-specific context.

#### Scenario: Request AI suggestion
- **WHEN** user clicks "Get AI Suggestions" button
- **THEN** show loading indicator
- **AND** send photo and persona context to caption generator
- **AND** prefill textarea with generated caption
- **AND** store suggestion metadata

#### Scenario: Regenerate suggestion
- **WHEN** user clicks "Regenerate" after receiving suggestion
- **THEN** generate a new variation
- **AND** replace textarea content with new suggestion
- **AND** maintain previous suggestions in history

#### Scenario: Caption generation with persona context
- **WHEN** generating caption
- **THEN** include persona voice and tone configuration
- **AND** include content pillar theme and description
- **AND** include photo detected objects
- **AND** include content pillar alignment
- **AND** avoid phrases from recent 20 posts

### Requirement: Context Building for Caption Generation
The system SHALL extract rich context from photo, persona, and pillar data for AI prompting.

#### Scenario: Extract photo context
- **WHEN** building context for caption generation
- **THEN** include detected objects/labels from photo analysis
- **AND** include image metadata (dimensions, colors)
- **AND** include any existing descriptions

#### Scenario: Extract pillar context
- **WHEN** photo belongs to a content pillar
- **THEN** include pillar name and description
- **AND** include pillar weight and priority
- **AND** include pillar guidelines

#### Scenario: Extract persona context
- **WHEN** building persona context
- **THEN** include caption_config (voice, tone, style)
- **AND** include hashtag_strategy
- **AND** include recent posting patterns

#### Scenario: Build repetition avoidance list
- **WHEN** building avoid-phrases list
- **THEN** fetch last 20 captions for persona
- **AND** extract common phrases (3+ words)
- **AND** identify overused words
- **AND** include in prompt as phrases to avoid

### Requirement: Post Preview and Metadata Display
The system SHALL display relevant photo and context metadata during post creation.

#### Scenario: Show photo preview
- **WHEN** viewing post creation form
- **THEN** display selected photo at appropriate size
- **AND** show photo filename and date
- **AND** show image dimensions

#### Scenario: Show context metadata
- **WHEN** viewing post creation form
- **THEN** display persona name and configuration summary
- **AND** display content pillar name and description
- **AND** display detected objects from photo analysis

#### Scenario: Show posting statistics
- **WHEN** viewing post creation form
- **THEN** show count of recent posts for persona
- **AND** show last posting time
- **AND** show suggested optimal posting time
- **AND** show hashtag usage patterns

## ADDED Requirements

### Requirement: Photo Model Namespace
The system SHALL use ContentPillars::Photo model for managing generated images.

#### Scenario: Photo belongs to pillar
- **WHEN** a photo is created from a pipeline run winner
- **THEN** the photo belongs_to a content_pillar
- **AND** the photo can be accessed via pillar.photos

#### Scenario: Photo belongs to persona
- **WHEN** a photo is created
- **THEN** the photo belongs_to the persona
- **AND** the photo can be accessed via persona.photos

#### Scenario: Query unposted photos by pillar
- **WHEN** browsing photos for a specific pillar
- **THEN** only photos belonging to that pillar are shown
- **AND** photos are ordered by creation date

## REMOVED Requirements

### Requirement: Filter by cluster
**Reason:** Clustering layer is being removed  
**Migration:** All cluster references replaced with content pillar references

### Requirement: Extract cluster context
**Reason:** Clusters no longer exist  
**Migration:** Cluster theme/context replaced with pillar description and guidelines
