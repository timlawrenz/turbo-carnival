# Growth Harness Spec

## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: NSFW Content Gate

The system SHALL run a third-party NSFW classifier on every freshly rendered
image before the image is imported as a photo or scheduled as a post, and SHALL
reject images classified as NSFW so they never enter the photo library or
queue.

#### Scenario: Clean render accepted
- **WHEN** a render completes and the classifier scores it below the NSFW
  threshold
- **THEN** the render is imported as a photo and scheduled normally

#### Scenario: NSFW render rejected
- **WHEN** a render completes and the classifier scores it at or above the
  NSFW threshold
- **THEN** no photo is imported, no post is scheduled, and an `nsfw_rejected`
  decision is recorded with the score and image path

#### Scenario: Gate failure is fail-closed
- **WHEN** the classifier cannot run (missing model, missing runtime, timeout)
- **THEN** the render is treated as rejected and the error is recorded; the
  gate never silently admits unmoderated content