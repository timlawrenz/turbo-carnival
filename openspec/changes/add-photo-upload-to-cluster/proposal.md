# Proposal: Add Photo Upload to Cluster

**Change ID:** `add-photo-upload-to-cluster`  
**Author:** Tim Lawrenz  
**Date:** 2025-12-08  
**Status:** PROPOSED

## Problem Statement

Users need a way to manually upload existing photos directly to a cluster. Currently, photos can only be created through the pipeline workflow (generate → vote → select winner → photo). This creates friction when users have existing content (e.g., from previous shoots, stock photos, or external sources) that they want to organize into their cluster structure.

**Current Workflow Limitation:**
1. User has 10 fashion photos on disk
2. User wants them in the "2025 Fashion" cluster
3. **NO WAY to do this** - must use image generation pipeline
4. Pipeline requires: AI generation → voting → winner selection
5. This is inappropriate for existing photos

**User Story:**
> "As a content creator, I have a folder of fashion photos from my photoshoot that I want to add to my '2025 Fashion' cluster, so I can organize and manage all my fashion content in one place."

## Proposed Solution

Add a photo upload interface to the cluster detail page that allows users to:
1. Select one or more image files from their computer
2. Upload them directly to a specific cluster
3. Have photos automatically linked to the cluster and persona
4. Support common image formats (JPG, PNG, WEBP)
5. Display uploaded photos immediately in the cluster gallery

**Key Benefits:**
- ✅ Manual content organization for existing photos
- ✅ Bridge gap between external content and platform
- ✅ Faster workflow for batch uploads
- ✅ No forced pipeline usage for manual uploads
- ✅ Maintains cluster organization

## Technical Approach

### Components to Add/Modify

**1. Upload UI (Cluster Detail Page)**
- Add "Upload Photos" button/section on cluster show page
- Multi-file picker with drag-and-drop support
- Progress indicators during upload
- Success/error feedback

**2. Controller Action**
- `ClustersController#upload_photos` action
- Handle multi-file upload via ActiveStorage
- Create Clustering::Photo records
- Link to cluster and persona
- Return JSON response for AJAX

**3. ActiveStorage Integration**
- Photos already have `image` attachment (via ActiveStorage)
- Reuse existing setup
- Store files in configured storage (disk/S3)

**4. Validation**
- File type validation (jpg, png, webp)
- File size limits (e.g., 10MB per file)
- Duplicate detection (optional)

### Implementation Flow

```
User clicks "Upload Photos"
    ↓
File picker opens (multi-select)
    ↓
User selects 5 fashion photos
    ↓
AJAX POST to /clusters/:id/upload_photos
    ↓
Controller processes each file:
  - Validates format/size
  - Creates Photo record
  - Attaches file via ActiveStorage
  - Links to cluster + persona
    ↓
Returns JSON with created photo IDs
    ↓
UI updates cluster gallery
    ↓
Success message shown
```

## Out of Scope

- **Bulk editing:** Metadata editing for uploaded photos (captions, dates)
- **Image processing:** Auto-resize, crop, filters (future enhancement)
- **Embedding generation:** AI embeddings for uploaded photos (future)
- **Clustering:** Auto-assignment to different clusters based on content
- **Versioning:** Photo replacement or versioning
- **External URLs:** Upload from URL vs file upload

These can be added in future proposals if needed.

## Migration Path

**No breaking changes** - this is purely additive:
- Existing pipeline workflow unchanged
- Existing photos unaffected
- New route and controller action only
- No database schema changes needed

## Success Criteria

**Must Have:**
1. ✅ Upload 1+ photos to a cluster via web UI
2. ✅ Photos appear in cluster gallery immediately
3. ✅ Photos linked to correct cluster and persona
4. ✅ File validation prevents invalid uploads
5. ✅ Works with JPG, PNG, WEBP formats

**Nice to Have:**
- Drag-and-drop upload
- Upload progress bar
- Thumbnail preview before upload
- Batch upload (10+ files at once)

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Large file uploads timeout | HIGH | Add file size limits (10MB), use direct upload |
| Storage costs with many uploads | MEDIUM | Monitor storage usage, document limits |
| Duplicate photos clutter clusters | LOW | Optional duplicate detection by filename |
| No metadata preserved (EXIF) | LOW | Document limitation, add in future if needed |

## Estimated Effort

- **Design/Planning:** 30 minutes (this proposal)
- **Implementation:** 2-3 hours
  - Controller action: 30 min
  - UI upload component: 1 hour
  - Validation & error handling: 30 min
  - Testing: 1 hour
- **Documentation:** 30 minutes
- **Total:** ~3-4 hours

## Open Questions

1. **File size limits:** 10MB per file? Total upload size limit?
2. **Storage location:** Use existing ActiveStorage config (disk/S3)?
3. **Path generation:** Auto-generate path or let user specify?
4. **Progress feedback:** Show per-file or overall progress?
5. **Error handling:** Fail entire batch or partial success?

**Proposed Answers:**
1. 10MB per file, 50MB total per upload
2. Use existing ActiveStorage config
3. Auto-generate: `uploads/cluster_#{id}/photo_#{timestamp}.ext`
4. Overall progress bar (simpler)
5. Partial success - create photos that succeed, report failures

## Next Steps

1. **Review this proposal** - get feedback on approach
2. **Create tasks.md** - break down implementation steps
3. **Create spec delta** - add requirements to clustering spec
4. **Validate with openspec** - ensure proposal is complete
5. **Get approval** - before starting implementation

## Related Changes

- **Depends on:** None (uses existing Photo model and ActiveStorage)
- **Related to:** `add-clustering` (modifies cluster functionality)
- **Enables:** Future bulk editing, EXIF metadata extraction proposals
