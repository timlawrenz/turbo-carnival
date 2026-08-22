# Change: Add manual photo upload to pillar page

## Why
Currently, photos for a content pillar are only created via pipeline runs.
This makes it difficult to attach existing photos (e.g., from a manual shoot) to a specific pillar like "Fashion & Style".

## What Changes
- Add an "Upload Photo" entry point on the pillar show page, next to the "Edit" button.
- Provide a simple UI to upload one or more image files and associate them with the current persona and content pillar.
- Persist uploads as `ContentPillars::Photo` records with attached ActiveStorage blobs.
- Redirect users back to the pillar show page with feedback when uploads succeed or fail.

## Impact
- Affected specs: a new `pillar-photos` capability.
- Affected code: `ContentPillarsController` / new photos controller or endpoint, pillar show view, routes, ActiveStorage-backed photo creation.
