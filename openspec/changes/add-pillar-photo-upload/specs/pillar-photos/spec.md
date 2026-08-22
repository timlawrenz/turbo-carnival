## ADDED Requirements

### Requirement: Pillar Photo Upload Entry Point
The system SHALL provide a visible "Upload Photo" action on the content pillar show page.

#### Scenario: Upload button placement
- **WHEN** a user visits `/personas/:persona_id/pillars/:id`
- **THEN** an "Upload Photo" button is rendered next to the "Edit" button in the header actions

#### Scenario: Upload button navigation
- **WHEN** a user clicks the "Upload Photo" button on a pillar page
- **THEN** they are taken to a form scoped to that persona and pillar to upload new photos

### Requirement: Pillar-Scoped Photo Upload
The system SHALL allow users to upload image files that become photos associated with a specific persona and content pillar.

#### Scenario: Successful single photo upload
- **WHEN** a user submits the upload form with a valid image file for a pillar
- **THEN** a `ContentPillars::Photo` record is created with `persona_id` set to the current persona
- **AND** `content_pillar_id` set to the current pillar
- **AND** the image is attached via ActiveStorage
- **AND** the user is redirected back to the pillar show page with a success notice

#### Scenario: Missing file validation
- **WHEN** a user submits the upload form without selecting a file
- **THEN** no photo is created
- **AND** the form is re-rendered with an error message indicating that an image file is required

#### Scenario: Invalid file type rejection
- **WHEN** a user attempts to upload a non-image file
- **THEN** the upload is rejected
- **AND** the user sees an error message explaining that only image files are allowed

### Requirement: Multiple Photo Upload (Optional)
The system MAY support uploading multiple photos for a pillar in a single request.

#### Scenario: Multiple files in one submission
- **WHEN** a user selects multiple image files (where supported by the browser and form)
- **THEN** one `ContentPillars::Photo` record is created per file
- **AND** all created photos are associated with the current persona and pillar
- **AND** the user is redirected back to the pillar show page with a summary of how many photos were uploaded

### Requirement: Upload Error Handling
The system SHALL provide clear feedback when pillar photo uploads fail.

#### Scenario: Storage failure
- **WHEN** an unexpected error occurs while attaching or saving an uploaded image
- **THEN** no partial `ContentPillars::Photo` records remain persisted without images
- **AND** the user is redirected back to the upload form or pillar page with a generic error message

#### Scenario: Unauthorized access
- **WHEN** an unauthorized user attempts to access the upload form or submit an upload for a pillar
- **THEN** the request is rejected according to existing authorization patterns (e.g., redirect or 403)
- **AND** no photo records are created
