## Phase 1: Preparation & Analysis

### 1.1 Database Backup & Audit
- [ ] 1.1.1 Backup current database
- [ ] 1.1.2 Run data integrity report (cluster → pillar mappings)
- [ ] 1.1.3 Count records: clusters, photos, pipeline_runs with cluster_id
- [ ] 1.1.4 Document orphaned records (photos/runs without valid cluster)

### 1.2 Create Pack Structure
- [ ] 1.2.1 Verify `packs/content_pillars/` exists with proper structure
- [ ] 1.2.2 Create `packs/content_pillars/app/models/content_pillars/` directory
- [ ] 1.2.3 Update package.yml if needed

---

## Phase 2: Database Migration

### 2.1 Add New Columns
- [ ] 2.1.1 Create migration: add `content_pillar_id` to `photos` table
- [ ] 2.1.2 Create migration: add `content_pillar_id` to `pipeline_runs` table
- [ ] 2.1.3 Add indexes on new foreign keys
- [ ] 2.1.4 Run migrations

### 2.2 Data Migration
- [ ] 2.2.1 Create data migration: populate `photos.content_pillar_id` from cluster's primary pillar
- [ ] 2.2.2 Create data migration: populate `pipeline_runs.content_pillar_id` from cluster's primary pillar
- [ ] 2.2.3 Handle edge cases (clusters with no pillar assignment)
- [ ] 2.2.4 Validate all photos have content_pillar_id
- [ ] 2.2.5 Validate all runs with cluster_id have content_pillar_id

### 2.3 Remove Old Schema
- [ ] 2.3.1 Create migration: remove foreign key `photos.cluster_id`
- [ ] 2.3.2 Create migration: remove foreign key `pipeline_runs.cluster_id`
- [ ] 2.3.3 Create migration: drop `pillar_cluster_assignments` table
- [ ] 2.3.4 Create migration: drop `clusters` table
- [ ] 2.3.5 Create migration: remove columns `photos.cluster_id` and `pipeline_runs.cluster_id`
- [ ] 2.3.6 Run migrations and verify schema

---

## Phase 3: Model Refactoring

### 3.1 Move Photo Model
- [ ] 3.1.1 Create `packs/content_pillars/app/models/content_pillars/photo.rb`
- [ ] 3.1.2 Copy content from `packs/clustering/app/models/clustering/photo.rb`
- [ ] 3.1.3 Update namespace: `Clustering::Photo` → `ContentPillars::Photo`
- [ ] 3.1.4 Change association: `belongs_to :cluster` → `belongs_to :content_pillar`
- [ ] 3.1.5 Update table_name if needed (keep as 'photos')
- [ ] 3.1.6 Remove cluster-specific scopes (`:in_cluster`)

### 3.2 Update Persona Model
- [ ] 3.2.1 Remove `has_many :clusters` association
- [ ] 3.2.2 Remove `has_many :photos, class_name: 'Clustering::Photo'`
- [ ] 3.2.3 Add `has_many :photos, through: :content_pillars, class_name: 'ContentPillars::Photo'`

### 3.3 Update ContentPillar Model
- [ ] 3.3.1 Remove `has_many :pillar_cluster_assignments`
- [ ] 3.3.2 Remove `has_many :clusters, through: :pillar_cluster_assignments`
- [ ] 3.3.3 Remove `alias_method :content_clusters, :clusters`
- [ ] 3.3.4 Add `has_many :photos, class_name: 'ContentPillars::Photo', foreign_key: :content_pillar_id`

### 3.4 Update PipelineRun Model
- [ ] 3.4.1 Change `belongs_to :cluster` → `belongs_to :content_pillar, optional: true`
- [ ] 3.4.2 Update `link_winner_to_cluster_if_completed` callback name
- [ ] 3.4.3 Update condition check: `cluster_id.present?` → `content_pillar_id.present?`

### 3.5 Update ImageCandidate Model
- [ ] 3.5.1 Update `create_photo_record` method to use `pipeline_run.content_pillar_id`
- [ ] 3.5.2 Change photo creation: use `ContentPillars::Photo` instead of `Clustering::Photo`
- [ ] 3.5.3 Update association to reference pillar: `content_pillar: pillar`

### 3.6 Remove Cluster Model Files
- [ ] 3.6.1 Delete `packs/clustering/app/models/clustering/cluster.rb`
- [ ] 3.6.2 Delete `packs/content_pillars/app/models/pillar_cluster_assignment.rb`
- [ ] 3.6.3 Delete `packs/clustering/app/models/clustering/photo.rb`

---

## Phase 4: Service Refactoring

### 4.1 Update Gap Analysis Service
- [ ] 4.1.1 Refactor `calculate_coverage` to work with pillars directly (no cluster loop)
- [ ] 4.1.2 Update `generate_pillar_recommendations` to skip cluster selection
- [ ] 4.1.3 Update `generate_cluster_recommendation` → `generate_pillar_recommendation`
- [ ] 4.1.4 Remove cluster references from recommendations data structure
- [ ] 4.1.5 Update `create_suggestions` to work without cluster_id
- [ ] 4.1.6 Update `generate_ai_suggestion` signature to remove cluster parameter
- [ ] 4.1.7 Update AI prompt to remove cluster context

### 4.2 Refactor Winner Linking Service
- [ ] 4.2.1 Rename `packs/clustering/app/services/link_winner_to_cluster.rb` → `link_winner_to_pillar.rb`
- [ ] 4.2.2 Update namespace and class name
- [ ] 4.2.3 Change logic to work with `pipeline_run.content_pillar`
- [ ] 4.2.4 Update all references to new service name

---

## Phase 5: Controller & View Updates

### 5.1 Update Controllers
- [ ] 5.1.1 Remove/archive `app/controllers/clustering/clusters_controller.rb`
- [ ] 5.1.2 Remove/archive `packs/clustering/app/controllers/clustering/clusters_controller.rb`
- [ ] 5.1.3 Update `app/controllers/content_pillars_controller.rb` to show photos directly
- [ ] 5.1.4 Update `app/controllers/personas_controller.rb` gap analysis display
- [ ] 5.1.5 Update `app/controllers/content_suggestions_controller.rb` if needed
- [ ] 5.1.6 Update run creation controllers to accept `content_pillar_id` instead of `cluster_id`

### 5.2 Update Views
- [ ] 5.2.1 Remove cluster views: `app/views/clustering/clusters/`
- [ ] 5.2.2 Update `app/views/content_pillars/show.html.erb` to display photos
- [ ] 5.2.3 Update `app/views/personas/show.html.erb` gap analysis section
- [ ] 5.2.4 Update `app/views/dashboard/index.html.erb` to remove cluster references
- [ ] 5.2.5 Update `app/views/scheduling/posts/` if they reference clusters

### 5.3 Update Routes
- [ ] 5.3.1 Remove cluster routes from `config/routes.rb`
- [ ] 5.3.2 Verify pillar routes handle photo display
- [ ] 5.3.3 Update run creation routes to use pillar_id parameter

---

## Phase 6: Testing & Validation

### 6.1 Model Tests
- [ ] 6.1.1 Update persona model specs (remove cluster associations)
- [ ] 6.1.2 Update content_pillar model specs (remove cluster, add photo associations)
- [ ] 6.1.3 Create/update photo model specs for `ContentPillars::Photo`
- [ ] 6.1.4 Update pipeline_run specs (content_pillar association)
- [ ] 6.1.5 Update image_candidate specs (photo creation)

### 6.2 Service Tests
- [ ] 6.2.1 Update gap_analysis_service specs
- [ ] 6.2.2 Update winner linking service specs

### 6.3 Integration Testing
- [ ] 6.3.1 Manual test: View persona with pillars and photos
- [ ] 6.3.2 Manual test: Run gap analysis
- [ ] 6.3.3 Manual test: Generate content suggestion for pillar
- [ ] 6.3.4 Manual test: Create pipeline run for pillar
- [ ] 6.3.5 Manual test: Select winner → verify photo created in correct pillar
- [ ] 6.3.6 Manual test: Schedule post from pillar photo
- [ ] 6.3.7 Verify no N+1 queries in pillar photo listings

---

## Phase 7: Cleanup & Documentation

### 7.1 Code Cleanup
- [ ] 7.1.1 Search codebase for "cluster" references (excluding migrations)
- [ ] 7.1.2 Remove unused imports/requires
- [ ] 7.1.3 Clean up factory files (remove cluster factories)
- [ ] 7.1.4 Update seed data if present
- [ ] 7.1.5 Remove `clustering` pack if now empty

### 7.2 Documentation
- [ ] 7.2.1 Update README.md with new architecture
- [ ] 7.2.2 Update any architecture diagrams
- [ ] 7.2.3 Document migration notes for future reference
- [ ] 7.2.4 Update API documentation if exists

### 7.3 Final Validation
- [ ] 7.3.1 Run full test suite
- [ ] 7.3.2 Check for console warnings/deprecations
- [ ] 7.3.3 Verify database integrity (foreign keys, indexes)
- [ ] 7.3.4 Performance check: key queries (pillar photos, gap analysis)
- [ ] 7.3.5 Final walkthrough of complete user workflow

---

## Rollback Plan

If issues arise:

1. **Before Phase 2.3 (dropping tables):**
   - Can rollback migrations to restore cluster_id columns
   - Revert code changes

2. **After Phase 2.3 (tables dropped):**
   - Restore from database backup
   - Revert all code changes
   - Re-run original migrations

**Critical Checkpoint:** Test thoroughly before running migrations in Phase 2.3
