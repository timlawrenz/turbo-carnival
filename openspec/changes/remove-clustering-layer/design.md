## Context

The application evolved from importing pre-existing images and using ML clustering to organize them, to generating content on-demand based on strategic gap analysis. This shift made the clustering layer obsolete:

- **Original design:** Import photos → ML cluster → assign clusters to pillars → pick photos
- **Current workflow:** Analyze gaps → suggest content for pillar → generate for pillar → pick photos
- **Problem:** Clusters add complexity without providing value in the new workflow

## Goals

1. **Simplify architecture** by removing the cluster abstraction layer
2. **Align data model with user mental model** (pillar-centric thinking)
3. **Reduce maintenance burden** (fewer models, associations, views)
4. **Improve gap analysis accuracy** (pillar-level metrics more meaningful)
5. **Enable clearer user workflows** (no cluster selection step)

## Non-Goals

- Preserving cluster historical data (archive migrations only)
- Maintaining backward compatibility (clean break acceptable)
- Supporting both clustered and non-clustered photos (all photos become pillar-based)

## Technical Decisions

### Decision 1: Single Big Migration vs Gradual Deprecation

**Chosen:** Single big migration (one-time data transformation)

**Rationale:**
- Single user (low risk of disrupting others)
- Clean break simpler than dual-mode support
- Database already local (easy to backup/restore)
- Faster to implement than gradual deprecation

**Alternatives considered:**
- Gradual deprecation: Add optional pillar_id, support both → too complex
- Feature flag: Keep clusters behind flag → unnecessary for single user

---

### Decision 2: Photo Model Location

**Chosen:** Move to `ContentPillars::Photo` (within content_pillars pack)

**Rationale:**
- Photos conceptually belong to pillars
- Keeps pack boundaries clean
- Clustering pack can be removed entirely
- Follows domain-driven design principles

**Alternatives considered:**
- Keep in clustering pack, rename namespace → pack would have misleading name
- Create new `photos` pack → over-engineering for single model

---

### Decision 3: Data Migration Strategy

**Chosen:** Map photos/runs to cluster's primary pillar, fallback to first pillar

**Strategy:**
```ruby
# For each photo:
1. Find photo.cluster
2. Get cluster.primary_pillar || cluster.pillars.first
3. Set photo.content_pillar_id
4. Validation: All photos must have content_pillar_id before dropping cluster_id
```

**Handling edge cases:**
- Clusters with no pillar assignment: Manual review + assign to default pillar
- Orphaned photos (no cluster): Assign to persona's first active pillar or delete
- Runs without cluster: Leave content_pillar_id NULL (historical data)

**Alternatives considered:**
- Create one pillar per cluster automatically → creates unnecessary pillars
- Delete orphaned data → might lose valuable content

---

### Decision 4: Gap Analysis Refactoring

**Chosen:** Calculate photo counts directly at pillar level

**Before:**
```ruby
pillar.clusters.each do |cluster|
  cluster.photos.count
end
```

**After:**
```ruby
pillar.photos.count
```

**Rationale:**
- Simpler query (one less join)
- More accurate (pillar is the strategic unit)
- Faster performance

**Impact:**
- Remove cluster-level granularity in coverage_data
- Recommendations become pillar-level only
- UI shows pillar photo counts directly

---

### Decision 5: Content Suggestions

**Chosen:** Generate suggestions at pillar level, remove cluster context

**Changes to AI prompt:**
- Remove: "Content Cluster: {name}, {ai_prompt}"
- Remove: Existing cluster names/themes list
- Keep: Existing photo prompts (to avoid duplication)
- Enhance: Pillar description and strategic context

**Rationale:**
- Clusters were causing repetitive suggestions ("coffee in Brooklyn")
- Pillar context is more strategic and varied
- AI can infer themes from existing photo prompts

---

## Database Schema Changes

### Add New Columns

```ruby
add_column :photos, :content_pillar_id, :bigint
add_foreign_key :photos, :content_pillars, column: :content_pillar_id

add_column :pipeline_runs, :content_pillar_id, :bigint
add_foreign_key :pipeline_runs, :content_pillars, column: :content_pillar_id

add_index :photos, :content_pillar_id
add_index :pipeline_runs, :content_pillar_id
```

### Data Migration

```ruby
# Populate photos.content_pillar_id
Photo.find_each do |photo|
  next unless photo.cluster_id
  
  cluster = Clustering::Cluster.find(photo.cluster_id)
  pillar = cluster.primary_pillar || cluster.pillars.first
  
  if pillar
    photo.update_column(:content_pillar_id, pillar.id)
  else
    # Handle orphaned: assign to persona's first pillar or log for review
    persona = Persona.find(photo.persona_id)
    default_pillar = persona.content_pillars.active.first
    
    if default_pillar
      photo.update_column(:content_pillar_id, default_pillar.id)
      Rails.logger.warn("Photo #{photo.id} assigned to default pillar #{default_pillar.name}")
    else
      Rails.logger.error("Photo #{photo.id} has no valid pillar - needs manual assignment")
    end
  end
end

# Populate pipeline_runs.content_pillar_id
PipelineRun.where.not(cluster_id: nil).find_each do |run|
  cluster = Clustering::Cluster.find(run.cluster_id)
  pillar = cluster.primary_pillar || cluster.pillars.first
  
  run.update_column(:content_pillar_id, pillar.id) if pillar
end
```

### Remove Old Schema

```ruby
remove_foreign_key :photos, :clusters
remove_foreign_key :pipeline_runs, :clusters
remove_column :photos, :cluster_id
remove_column :pipeline_runs, :cluster_id

drop_table :pillar_cluster_assignments
drop_table :clusters
```

---

## Model Changes

### Before (with clusters)

```ruby
class Persona
  has_many :content_pillars
  has_many :clusters, class_name: 'Clustering::Cluster'
  has_many :photos, class_name: 'Clustering::Photo'
end

class ContentPillar
  belongs_to :persona
  has_many :pillar_cluster_assignments
  has_many :clusters, through: :pillar_cluster_assignments
end

class Clustering::Cluster
  belongs_to :persona
  has_many :photos
  has_many :pipeline_runs
  has_many :pillar_cluster_assignments
  has_many :pillars, through: :pillar_cluster_assignments
end

class Clustering::Photo
  belongs_to :cluster
  belongs_to :persona
end

class PipelineRun
  belongs_to :cluster, optional: true
end
```

### After (without clusters)

```ruby
class Persona
  has_many :content_pillars
  has_many :photos, through: :content_pillars, class_name: 'ContentPillars::Photo'
end

class ContentPillar
  belongs_to :persona
  has_many :photos, class_name: 'ContentPillars::Photo', foreign_key: :content_pillar_id
end

class ContentPillars::Photo
  belongs_to :content_pillar
  belongs_to :persona
end

class PipelineRun
  belongs_to :content_pillar, optional: true
end
```

---

## Service Changes

### Gap Analysis Service

**Key changes:**
1. Remove cluster iteration in `calculate_coverage`
2. Calculate photo counts directly from pillar
3. Generate pillar-level recommendations (not cluster-level)
4. Update AI prompt to remove cluster context

**Before:**
```ruby
def calculate_coverage
  pillars.map do |pillar|
    clusters_data = pillar.clusters.map { |cluster| ... }
    { pillar_id: ..., clusters: clusters_data }
  end
end
```

**After:**
```ruby
def calculate_coverage
  pillars.map do |pillar|
    {
      pillar_id: pillar.id,
      pillar_name: pillar.name,
      total_photos: pillar.photos.count,
      last_photo_at: pillar.photos.maximum(:created_at),
      coverage_score: calculate_pillar_score(pillar)
    }
  end
end
```

---

## Migration Plan

### Phase Breakdown

**Phase 1: Preparation (30 min)**
- Database backup
- Audit current data
- Identify edge cases

**Phase 2: Schema Migration (1-2 hours)**
- Add new columns
- Populate with data migration
- Validate data integrity
- Drop old columns/tables

**Phase 3: Code Refactoring (1 day)**
- Move models
- Update associations
- Refactor services
- Update controllers/views

**Phase 4: Testing (4-6 hours)**
- Manual workflow testing
- Fix any issues
- Performance validation

### Rollback Strategy

**Before dropping tables (Phase 2.3):**
- Can safely rollback migrations
- Restore cluster_id columns
- Revert code changes

**After dropping tables:**
- Restore from database backup
- Re-run old migrations
- Revert all code changes

**Critical checkpoint:** Phase 2.2 validation must pass before proceeding to Phase 2.3

---

## Risks & Mitigations

### Risk 1: Data Loss

**Impact:** High  
**Probability:** Low  
**Mitigation:**
- Full database backup before starting
- Test migration on copy first
- Validate data integrity at each step
- Keep migrations reversible until final drop

---

### Risk 2: Broken References

**Impact:** Medium  
**Probability:** Medium  
**Mitigation:**
- Comprehensive grep for "cluster" in codebase
- Update tests to catch association errors
- Manual testing of all workflows
- Incremental code changes with validation

---

### Risk 3: Performance Degradation

**Impact:** Low  
**Probability:** Very Low  
**Mitigation:**
- Simpler queries (fewer joins) should improve performance
- Add indexes on new foreign keys
- Monitor query performance after migration

---

## Open Questions

None - all decisions made based on requirements.

---

## Success Metrics

1. **Zero data loss:** All photos migrated successfully
2. **Complete workflow:** Gap analysis → suggestion → generation → posting works end-to-end
3. **Code cleanliness:** No cluster references in codebase (except migrations)
4. **Performance:** Photo/pillar queries faster or same speed
5. **User experience:** Simpler navigation and clearer mental model

---

## Future Enhancements

After this change is complete:

1. **Enhanced gap analysis:** More sophisticated pillar-level metrics
2. **Photo tagging:** Add tags/categories within pillars for finer organization
3. **Pillar templates:** Pre-configured pillar sets for different persona types
4. **Bulk operations:** Select multiple photos from pillar for batch scheduling
