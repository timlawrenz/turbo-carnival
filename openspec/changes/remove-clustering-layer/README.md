# Remove Clustering Layer

**Status:** Proposed (awaiting approval)  
**Created:** 2025-12-10  
**Owner:** Tim

## Quick Summary

Remove the clustering abstraction layer and make content pillars the primary organizational unit for photos. This simplifies the architecture from `Persona → Pillars → Clusters → Photos` to `Persona → Pillars → Photos`.

## Why This Change?

Clusters were originally created for ML-based organization of imported images. With the shift to on-demand AI content generation based on gap analysis, clusters have become unnecessary complexity that doesn't align with the user's mental model.

## What's in This Directory?

- **proposal.md** - Complete proposal with rationale, changes, impact, and benefits
- **design.md** - Technical decisions, migration strategy, schema changes, and risk analysis
- **tasks.md** - Detailed 7-phase implementation checklist with 70+ tasks
- **specs/** - Delta specifications for affected capabilities (pipeline, post-creation)

## Key Metrics

- **Effort:** 2-3 days
- **Risk:** Medium (requires data migration)
- **Breaking Changes:** Yes (cluster model removed, photo model relocated)
- **Affected Models:** 8 models (4 modified, 2 removed, 1 moved, 1 new location)
- **Database Changes:** 4 tables affected (2 dropped, 2 columns added/removed)

## Implementation Phases

1. **Preparation** (30 min) - Backup and audit
2. **Database Migration** (1-2 hours) - Schema changes and data migration
3. **Model Refactoring** (1 day) - Move Photo, update associations
4. **Service Refactoring** (3-4 hours) - Gap analysis and winner linking
5. **Controller/View Updates** (3-4 hours) - Remove cluster UI
6. **Testing** (4-6 hours) - Full workflow validation
7. **Cleanup** (2-3 hours) - Remove unused code, update docs

## Critical Decisions

✅ **Migration Strategy:** Single big migration (not gradual)  
✅ **Photo Namespace:** Move to `ContentPillars::Photo`  
✅ **Data Mapping:** Use cluster's primary pillar assignment  
✅ **Gap Analysis:** Pillar-level only (remove cluster granularity)  
✅ **AI Suggestions:** Target pillars directly (skip cluster context)

## Validation Status

```bash
✓ openspec validate remove-clustering-layer --strict
  → Change is valid with proper deltas
```

## Before Implementation

1. **Read all proposal files** to understand scope
2. **Review design.md decisions** to understand technical approach
3. **Backup production database** (this is your local DB)
4. **Test migration on copy** if you want extra safety
5. **Follow tasks.md checklist** sequentially

## Quick Commands

```bash
# View full proposal
openspec show remove-clustering-layer

# Validate
openspec validate remove-clustering-layer --strict

# View deltas only
openspec show remove-clustering-layer --json --deltas-only

# After implementation
openspec archive remove-clustering-layer
```

## Questions or Changes?

Review the proposal files and discuss any concerns before beginning implementation. The design decisions can be revisited if needed.
