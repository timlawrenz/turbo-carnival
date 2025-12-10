# Remove Clustering Layer: Simplify to Pillar-Based Content Architecture

**Status:** Proposed  
**Created:** 2025-12-10  
**Effort:** 2-3 days (migration + refactoring)  
**Risk:** Medium (breaking change with data migration)

---

## Why

The clustering layer was originally created to group ML-clustered imported images. With the shift to on-demand content generation based on gap analysis, clusters have become unnecessary complexity:

1. **Gap analysis targets pillars** - not clusters
2. **Content suggestions should be pillar-specific** - not cluster-specific
3. **Clusters add an unnecessary intermediate layer** - between pillars and photos
4. **User workflow is pillar-centric** - "create content for this pillar"

The new architecture eliminates clusters and makes pillars the primary organizational unit for content.

---

## What Changes

### Architecture Simplification

**BEFORE:**
```
Persona → Content Pillars → Clusters → Photos
                  ↓
            Pipeline Runs → Winners → Photos
```

**AFTER:**
```
Persona → Content Pillars → Photos
                  ↓
            Pipeline Runs → Winners → Photos
```

### Breaking Changes

1. **BREAKING:** Remove `Clustering::Cluster` model and associations
2. **BREAKING:** Remove `PillarClusterAssignment` join table
3. **BREAKING:** Move `Clustering::Photo` to `ContentPillars::Photo`
4. **BREAKING:** Change `PipelineRun#cluster_id` to `content_pillar_id`
5. **BREAKING:** Update `ContentSuggestion` to reference pillars directly
6. **BREAKING:** Remove cluster-based gap analysis

### Data Migration

- Migrate existing `Clustering::Photo` records to `ContentPillars::Photo`
- Assign photos to pillars based on their cluster's pillar assignment
- Update pipeline runs to reference pillars instead of clusters
- Archive cluster data (keep for reference but not active)

### New Pack Structure

Consider introducing a `content_pillars` pack (if not already present) to house:
- `ContentPillar` model
- `ContentPillars::Photo` model (renamed from `Clustering::Photo`)
- Pillar-specific services and controllers

---

## Impact

### Affected Specs
- `pipeline` - PipelineRun associations change
- `post-creation` - Photo model moves and changes associations

### Affected Code

**Models:**
- `app/models/persona.rb` - remove cluster associations
- `packs/content_pillars/app/models/content_pillar.rb` - remove cluster associations
- `packs/clustering/app/models/clustering/cluster.rb` - **REMOVED**
- `packs/clustering/app/models/clustering/photo.rb` - **MOVED** to `ContentPillars::Photo`
- `packs/content_pillars/app/models/pillar_cluster_assignment.rb` - **REMOVED**
- `packs/pipeline/app/models/pipeline_run.rb` - change `cluster_id` to `content_pillar_id`
- `packs/pipeline/app/models/image_candidate.rb` - update photo creation logic
- `app/models/content_suggestion.rb` - already references pillar (no change needed)
- `app/models/gap_analysis.rb` - update coverage calculation

**Services:**
- `app/services/gap_analysis_service.rb` - refactor to work with pillars only
- `packs/clustering/app/services/link_winner_to_cluster.rb` - rename/refactor to link to pillar
- Any cluster-specific controllers/views

**Database:**
- Migration to drop `clusters` table
- Migration to drop `pillar_cluster_assignments` table
- Migration to rename `photos.cluster_id` to `content_pillar_id`
- Migration to rename `pipeline_runs.cluster_id` to `content_pillar_id`
- Data migration to move photos from clusters to pillars

**UI:**
- Remove cluster management pages
- Update pillar show pages to display photos directly
- Update run creation to select pillar instead of cluster
- Simplify navigation (remove cluster level)

### User Workflow Changes

**OLD:**
1. View gap analysis → identifies cluster needs content
2. Generate AI suggestion for cluster
3. Create run for cluster
4. Winner becomes photo in cluster
5. Pick photo from cluster to post

**NEW:**
1. View gap analysis → identifies pillar needs content
2. Generate AI suggestion for pillar
3. Create run for pillar
4. Winner becomes photo in pillar
5. Pick photo from pillar to post

---

## Benefits

1. **Simpler mental model** - one less layer to understand
2. **Clearer user workflow** - pillar-centric operations
3. **Less code to maintain** - remove cluster pack
4. **Better aligned with gap analysis** - pillars are the strategic unit
5. **Easier to extend** - fewer associations to manage

---

## Risks and Mitigations

### Risk: Data Loss During Migration
**Mitigation:** 
- Comprehensive backup before migration
- Reversible migrations with down methods
- Test migration on copy of production data first

### Risk: Breaking Existing Workflows
**Mitigation:**
- Single user (you) - easy to coordinate
- Can rebuild clusters if needed from archived data
- Migration is straightforward (cluster → pillar mapping)

### Risk: Performance Impact
**Mitigation:**
- Fewer joins needed (simpler queries)
- Performance should improve, not degrade

---

## Migration Strategy

### Phase 1: Preparation (30 min)
1. Backup database
2. Document current cluster → pillar mappings
3. Test migration script on database copy

### Phase 2: Schema Migration (1-2 hours)
1. Add `content_pillar_id` to photos table
2. Add `content_pillar_id` to pipeline_runs table
3. Data migration: populate pillar_id from cluster associations
4. Verify data integrity
5. Remove foreign keys and drop cluster tables

### Phase 3: Code Refactoring (1 day)
1. Move `Clustering::Photo` to `ContentPillars::Photo`
2. Update all associations to use `content_pillar` instead of `cluster`
3. Refactor services (gap analysis, winner linking)
4. Update controllers and views
5. Remove cluster-related code

### Phase 4: Testing & Cleanup (4-6 hours)
1. Manual testing of complete workflow
2. Verify gap analysis works correctly
3. Test content generation and winner selection
4. Clean up unused files and routes
5. Update documentation

---

## Open Questions

1. ~~Should we keep cluster data in an archive table?~~ → **Decision: Drop tables, keep migrations for history**
2. ~~Do we need backward compatibility?~~ → **Decision: No, clean break**
3. ~~Should photos belong to pack content_pillars or separate pack?~~ → **Decision: Move to content_pillars pack**

---

## Success Criteria

- [ ] All photos migrated to pillars correctly
- [ ] All runs reference pillars instead of clusters
- [ ] Gap analysis works with pillar-only model
- [ ] Content suggestions target pillars
- [ ] Winner selection creates photos in correct pillar
- [ ] UI shows pillar-based content organization
- [ ] No references to clusters in codebase (except migrations)
- [ ] Complete workflow tested: gap analysis → suggestion → generation → winner → photo → post
