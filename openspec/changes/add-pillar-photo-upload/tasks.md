## 1. Implementation
- [ ] 1.1 Add routes for pillar-scoped photo uploads (new/create) under personas/:persona_id/pillars/:pillar_id.
- [ ] 1.2 Implement controller actions to render the upload form and create `ContentPillars::Photo` records with attached images.
- [ ] 1.3 Add an "Upload Photo" button to the pillar show page next to the "Edit" button, linking to the new upload form.
- [ ] 1.4 Implement a basic upload form supporting at least single-file upload (optionally multiple files).
- [ ] 1.5 Add validations and user-facing error handling for failed uploads.

## 2. Testing
- [ ] 2.1 Add request/controller specs covering successful upload, validation failure, and non-existent pillar/persona.
- [ ] 2.2 Add view/feature specs to ensure the "Upload Photo" button appears on the pillar show page and round-trips back after upload.

## 3. Docs & Cleanup
- [ ] 3.1 Update README or relevant docs to mention manual photo upload on pillar pages.
- [ ] 3.2 Run `openspec validate add-pillar-photo-upload --strict` and fix any issues.
