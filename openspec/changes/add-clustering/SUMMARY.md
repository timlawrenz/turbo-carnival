# Clustering OpenSpec - Summary (Option B - Essential Integration)

## ✅ Status: READY FOR IMPLEMENTATION

**Change ID:** `add-clustering`  
**Priority:** HIGH (Essential for workflow completion)  
**Effort:** 2-3 days (60 tasks, ~18 hours)  
**Risk:** Low  
**Validation:** ✅ PASSED

---

## 📋 What This Adds

**Clustering** is the missing link between strategic planning and content generation:

- **Content Organization** - Group related images by theme
- **Pipeline Integration** - Runs belong to clusters
- **Auto-linking** - Winners automatically added to clusters
- **Pillar Connection** - Clusters serve pillar themes
- **Ready for Scheduling** - Clustered content can be scheduled

**THE COMPLETE WORKFLOW:**
```
Gap in Pillar → Create Cluster → Run Pipeline → Vote → Winner 
→ Auto-linked to Cluster → Ready for Scheduling
```

---

## 📦 Deliverables

### Database
- `clusters` table (name, persona_id, status, ai_prompt, photos_count)
- `cluster_id` added to `pipeline_runs` (optional FK)
- FK constraint updated on `pillar_cluster_assignments`

### Pack Structure
- `packs/clustering/` (Packwerk compliant)
- Models: `Clustering::Cluster` (namespaced)
- Service: `LinkWinnerToCluster`
- Public API: `Clustering` module

### Integration
- PipelineRun.belongs_to :cluster
- ContentPillar.has_many :clusters (through assignments)
- Persona.has_many :clusters
- Auto-link callback on run completion

### Web UI
- Cluster CRUD (nested under persona)
- Show winners in cluster
- Assign clusters to pillars
- Create run with cluster

---

## 🎯 Requirements (9 Total)

1. **Cluster Definition and Management** - Basic CRUD
2. **Pipeline Run Integration** - cluster_id on runs
3. **Auto-link Winner to Cluster** - On completion callback
4. **Pillar-Cluster Assignments** - Many-to-many
5. **Basic Cluster UI** - Web interface
6. **Cluster Content Display** - Show winners
7. **Public API Module** - Clustering facade
8. **Packwerk Compliance** - Modular architecture
9. **End-to-End Workflow** - Complete integration test

---

## 📊 Task Breakdown (60 tasks)

| Section | Tasks | Duration |
|---------|-------|----------|
| Database Schema | 5 | 2 hours |
| Pack Structure | 3 | 30 min |
| Models | 8 | 2 hours |
| Auto-linking | 5 | 1.5 hours |
| Controller & Routes | 6 | 1.5 hours |
| Views | 7 | 2 hours |
| Public API | 5 | 1 hour |
| Integration with Pillars | 4 | 1 hour |
| Pipeline Integration | 4 | 1 hour |
| Testing | 6 | 2 hours |
| Packwerk | 4 | 30 min |
| End-to-End Test | 6 | 1 hour |
| Documentation | 3 | 30 min |
| Import Sample Data | 3 | 30 min |
| OpenSpec | 4 | 30 min |

**Total:** ~18 hours (2-3 work days)

---

## 🔗 Dependencies

**Requires:**
- ✅ Personas pack
- ✅ Content Pillars pack
- ✅ Pipeline pack

**Enables:**
- ⏳ Scheduling (Week 4)
- ⏳ Gap Analysis (enhanced)
- ⏳ Photo Management (Week 3)

---

## 🎬 What This Unlocks

**Before Clustering:**
```
PipelineRun → ImageCandidates → Winner (isolated, nowhere to go)
```

**After Clustering:**
```
Pillar → Cluster → PipelineRun → ImageCandidates → Winner
                                                      ↓
                                              (auto-linked to cluster)
                                                      ↓
                                              (ready for scheduling)
```

**Gap Analysis Now Works:**
- Pillar "Lifestyle" needs 9 posts
- Check clusters assigned to pillar
- Count unposted winners in those clusters
- GAP = 9 - winner_count

---

## 📝 Simplified Scope (vs fluffy-train)

**INCLUDED (Essential):**
- ✅ Cluster model & CRUD
- ✅ cluster_id on runs
- ✅ Auto-link winners
- ✅ Pillar assignments
- ✅ Basic UI

**DEFERRED (Week 3):**
- ⏳ Photo model & Active Storage
- ⏳ Photo upload/import
- ⏳ Photo analysis/embeddings
- ⏳ Advanced clustering algorithms

**Why Simplified:**
- ImageCandidates serve as content for now
- Gets workflow working ASAP
- Photo management is separate concern

---

## 🚀 Next Steps

1. **Review proposal** - Ensure approach is correct
2. **Start implementation** - Follow tasks.md
3. **Test with Sarah** - Real pillar data
4. **Verify workflow** - Gap → Cluster → Run → Winner → Ready

**Ready to implement?** Say "Let's add clustering"

---

## 📄 Files Created

```
openspec/changes/add-clustering/
├── proposal.md        (why Option B, simplified scope)
├── tasks.md           (60 implementation tasks)
├── specs/
│   └── clustering/
│       └── spec.md    (9 requirements, 15+ scenarios)
└── SUMMARY.md         (this file)
```

**Validation:**
```bash
$ openspec validate add-clustering --strict
Change 'add-clustering' is valid
```

---

