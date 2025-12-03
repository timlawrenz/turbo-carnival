# Change: Add Clustering Capability (Option B - Essential Integration)

## Why

**The Missing Link:** Clusters are the bridge between strategic planning (pillars) and content generation (pipeline runs). Without clusters, generated content has nowhere to go and cannot be scheduled for posting.

**Current Problem:**
- Pipeline runs generate winners but they're isolated
- No way to group related content
- No connection between strategic pillars and generated images
- Cannot schedule posts (no content library)

**This enables the complete workflow:**
```
Gap Analysis → AI Suggestion → Create Cluster → Run Pipeline 
→ Vote on Candidates → Winner auto-links to Cluster → Schedule Post
```

This is **Week 2, Day 1-3** of the integration roadmap, but we're prioritizing it to get the end-to-end workflow working.

## What Changes

**Core Integration (Essential):**
- NEW: Clustering pack (models, basic API)
- NEW: `clusters` table (name, persona_id, status, ai_prompt)
- NEW: `cluster_id` to `pipeline_runs` (optional FK)
- NEW: Auto-link winner when run completes
- NEW: Basic cluster management UI

**Deferred (Week 3):**
- Photo management (Active Storage)
- Advanced clustering algorithms
- Photo analysis/embeddings
- Batch operations

## Impact

**Affected Specs:**
- NEW spec: `clustering` (adapted from fluffy-train)

**Affected Code:**
- NEW pack: `packs/clustering/`
- NEW migration: `clusters`, add `cluster_id` to `pipeline_runs`
- UPDATED: PipelineRun model (belongs_to :cluster)
- UPDATED: ContentPillar model (has_many :clusters through assignments)
- NEW controller: ClustersController (basic CRUD)
- NEW: Auto-link callback on run completion

**Dependencies:**
- Requires: Personas ✅, Content Pillars ✅
- Required by: Scheduling (Week 4), Photo Management (Week 3)

## Migration Strategy

**Simplified Approach (Option B):**

1. **Import core cluster model** (not photos yet)
2. **Add cluster_id to runs** (connects generation to library)
3. **Basic UI** (create cluster, view clusters, assign to pillar)
4. **Auto-linking** (winner → cluster on completion)
5. **Test workflow** (gap → create cluster → run → winner → ready to schedule)

**Photos deferred:** ImageCandidates serve as content for now. Photo import comes later.

## Migration Path

**For existing runs:**
- Existing 23 runs have no cluster (cluster_id NULL)
- New runs can optionally belong to a cluster
- Backward compatible - runs work with or without clusters

**For testing:**
- Create sample cluster for each pillar
- Manually create run with cluster_id
- Verify winner links to cluster

## Notes

- Simplified from fluffy-train (no photos yet, just ImageCandidates)
- Focuses on workflow completion, not feature completeness
- Photo management is Week 3 (Active Storage, imports, etc)
- This unblocks scheduling implementation (Week 4)
