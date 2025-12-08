# Tasks: Add Photo Upload to Cluster

**Change ID:** `add-photo-upload-to-cluster`  
**Status:** PROPOSED

## Phase 1: Foundation (1 hour)

### Route & Controller
- [ ] Add route `POST /personas/:persona_id/pillars/:pillar_id/clusters/:id/upload_photos`
- [ ] Create `ClustersController#upload_photos` action
  - [ ] Handle multiple file params
  - [ ] Validate file types (jpg, png, webp)
  - [ ] Validate file sizes (max 10MB per file)
  - [ ] Create Photo records for each valid file
  - [ ] Attach files via ActiveStorage
  - [ ] Link to cluster and persona
  - [ ] Return JSON response with success/errors

### Model Validation
- [ ] Add file type validation to Photo model (if not exists)
- [ ] Add file size validation to Photo model (if not exists)
- [ ] Ensure ActiveStorage attachment configured on Photo

## Phase 2: UI Implementation (1.5 hours)

### Upload Interface
- [ ] Add "Upload Photos" section to cluster show page
- [ ] Create file input with `multiple` attribute
- [ ] Style upload button using design system components
- [ ] Add drag-and-drop zone (optional, nice-to-have)

### Upload Handling
- [ ] Implement AJAX form submission
- [ ] Show upload progress indicator
- [ ] Handle success response
  - [ ] Update cluster gallery with new photos
  - [ ] Show success message
  - [ ] Reset file input
- [ ] Handle error response
  - [ ] Display validation errors
  - [ ] Show which files failed
  - [ ] Allow retry

### Gallery Update
- [ ] Ensure uploaded photos appear in cluster gallery
- [ ] Add Turbo Stream support for real-time updates (optional)
- [ ] Show photo count update

## Phase 3: Polish (30 minutes)

### User Experience
- [ ] Add file format hint text ("JPG, PNG, WEBP")
- [ ] Add file size hint text ("Max 10MB per file")
- [ ] Preview selected files before upload (optional)
- [ ] Show thumbnail after successful upload

### Error Handling
- [ ] Handle network errors gracefully
- [ ] Show clear error messages for:
  - [ ] Invalid file types
  - [ ] Files too large
  - [ ] Upload failures
  - [ ] Network issues

## Phase 4: Testing (1 hour)

### Manual Testing
- [ ] Upload single photo
- [ ] Upload multiple photos (5+ files)
- [ ] Test with different formats (JPG, PNG, WEBP)
- [ ] Test file size validation (try 11MB file)
- [ ] Test invalid file type (try .txt file)
- [ ] Verify photos appear in cluster gallery
- [ ] Verify photos linked to correct cluster
- [ ] Verify photos linked to correct persona

### Edge Cases
- [ ] Upload with no files selected
- [ ] Upload duplicate filename
- [ ] Upload very large batch (20+ files)
- [ ] Upload while another upload in progress
- [ ] Network interruption during upload

### Browser Compatibility
- [ ] Test in Chrome
- [ ] Test in Firefox
- [ ] Test in Safari (if available)

## Phase 5: Documentation (30 minutes)

- [ ] Add user documentation for photo upload feature
- [ ] Document file size and type limitations
- [ ] Add inline help text in UI
- [ ] Update cluster spec with new requirements

## Estimated Total: 4.5 hours

## Dependencies
- ActiveStorage configured (✓ already exists)
- Photo model with image attachment (✓ already exists)
- Cluster detail page exists (✓ already exists)

## Notes
- Consider adding Turbo Streams for real-time gallery updates
- Could add thumbnail generation in future enhancement
- Could add EXIF metadata extraction in future enhancement
- Could add duplicate detection by image hash in future enhancement
