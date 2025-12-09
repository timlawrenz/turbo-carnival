## ADDED Requirements

### Requirement: Post Record Management
The system SHALL maintain a record of all scheduled and posted content with status tracking.

#### Scenario: Create draft post
- **WHEN** a post is created with photo, persona, and caption
- **THEN** a draft post record is created with status 'draft'
- **AND** the post is associated with the photo and persona

#### Scenario: Unique photo-persona constraint
- **WHEN** attempting to create a post for the same photo-persona combination
- **THEN** the system SHALL prevent duplicate posts

### Requirement: Post State Machine
The system SHALL manage post lifecycle through defined states: draft, scheduled, posting, posted, and failed.

#### Scenario: Schedule draft post
- **WHEN** a draft post receives an Instagram post ID
- **THEN** the status transitions to 'scheduled'

#### Scenario: Start posting process
- **WHEN** it's time to publish a scheduled post
- **THEN** the status transitions to 'posting'

#### Scenario: Mark as posted
- **WHEN** Instagram confirms successful publication
- **THEN** the status transitions to 'posted'
- **AND** the posted_at timestamp is recorded

#### Scenario: Handle posting failure
- **WHEN** posting to Instagram fails
- **THEN** the status transitions to 'failed'
- **AND** error details are logged

### Requirement: Instagram API Integration
The system SHALL publish posts to Instagram using the Instagram Graph API.

#### Scenario: Create Instagram post
- **WHEN** sending a post to Instagram with image URL and caption
- **THEN** create a media container on Instagram
- **AND** publish the media container
- **AND** return the Instagram post ID

#### Scenario: Handle API errors
- **WHEN** the Instagram API returns an error
- **THEN** raise an Instagram::Client::Error with details
- **AND** trigger command rollback

### Requirement: Public Photo URL Generation
The system SHALL generate publicly accessible URLs for photos to be posted.

#### Scenario: Generate URL for attached image
- **WHEN** generating a public URL for a photo
- **THEN** verify the image is attached via ActiveStorage
- **AND** return a permanent public URL

#### Scenario: Missing image attachment
- **WHEN** a photo has no attached image
- **THEN** fail with error message

### Requirement: Post Scheduling Command Chain
The system SHALL execute a transactional command chain to schedule posts.

#### Scenario: Successful scheduling chain
- **WHEN** scheduling a post with photo, persona, and caption
- **THEN** create post record
- **AND** generate public photo URL
- **AND** send post to Instagram
- **AND** update post with Instagram ID
- **AND** return the scheduled post

#### Scenario: Chain rollback on failure
- **WHEN** any command in the chain fails
- **THEN** rollback all previously executed commands in reverse order
- **AND** clean up created resources

### Requirement: Automated Scheduled Posting
The system SHALL automatically publish posts when their scheduled time arrives.

#### Scenario: Post scheduled posts at appointed time
- **WHEN** the scheduled posting task runs
- **THEN** find all posts with scheduled_at or optimal_time_calculated <= now
- **AND** publish each post to Instagram
- **AND** update status to 'posted' on success
- **AND** update status to 'failed' on error

#### Scenario: No posts scheduled
- **WHEN** no posts are due for publication
- **THEN** display next scheduled post information
- **AND** exit gracefully

### Requirement: Content Strategy Integration
The system SHALL support creating scheduled posts using content strategy metadata.

#### Scenario: Create post with cluster and strategy
- **WHEN** creating a scheduled post from content strategy
- **THEN** store cluster_id and strategy_name
- **AND** store optimal_time_calculated from strategy
- **AND** store hashtags from strategy
- **AND** generate caption with hashtags

#### Scenario: Record in strategy history
- **WHEN** a scheduled post is successfully posted
- **AND** the post has cluster and strategy information
- **THEN** create a ContentStrategy::HistoryRecord

### Requirement: Instagram Credentials Management
The system SHALL securely load Instagram API credentials from Rails credentials.

#### Scenario: Load required credentials
- **WHEN** initializing the Instagram client
- **THEN** load app_id, app_secret, access_token, and account_id
- **AND** verify all credentials are present
- **AND** raise ArgumentError if any are missing
