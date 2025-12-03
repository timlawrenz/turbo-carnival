# Content Pillars OpenSpec - Summary

## ✅ Status: READY FOR IMPLEMENTATION

**Change ID:** `add-content-pillars`  
**Week:** 1, Day 3-4  
**Effort:** 2 days (59 tasks)  
**Risk:** Low  
**Validation:** ✅ PASSED

---

## 📋 What This Adds

**Content Pillars** enable strategic, weighted content planning for personas:

- **Strategic Themes** (e.g., "Fitness 30%", "Travel 40%", "Food 20%")
- **Temporal Planning** (seasonal pillars with start/end dates)
- **Gap Analysis** (showing which themes need more content)
- **Guidelines** (tone, topics, style per pillar stored in JSONB)
- **Weight Validation** (total active pillars ≤ 100% per persona)

---

## 📦 Deliverables

### Database
- `content_pillars` table (9 fields + timestamps)
- `pillar_cluster_assignments` table (stub for Week 2)
- Migrations with constraints and indexes

### Pack Structure
- `packs/content_pillars/` (Packwerk compliant)
- Models: `ContentPillar`, `PillarClusterAssignment`
- Services: `GapAnalysisService`
- Public API: `ContentPillars` module

### Web UI
- Pillars section on persona show page
- Create/Edit/Delete pillar forms
- Gap analysis visualization
- Nested routes: `/personas/:id/content_pillars`

### Integration
- Import Sarah's pillars from fluffy-train
- Update Persona model (has_many :content_pillars)
- Rake task for import

---

## 🎯 Requirements (8 Total)

1. **Content Pillar Definition and Management** - CRUD with validations
2. **Temporal Pillar Management** - Date-bounded pillars
3. **Pillar Cluster Assignments** - Join table (Week 2 usage)
4. **Basic Gap Analysis Service** - Calculate content needs
5. **Web UI for Pillar Management** - Full web interface
6. **Public API Module** - ContentPillars facade
7. **Packwerk Compliance** - Modular architecture
8. **Import from Fluffy-Train** - Migration tooling

---

## 📊 Task Breakdown (59 tasks)

| Section | Tasks | Duration |
|---------|-------|----------|
| Database Schema | 4 | 1 hour |
| Pack Structure | 3 | 30 min |
| Models | 6 | 2 hours |
| Services | 4 | 1.5 hours |
| Controller & Routes | 7 | 2 hours |
| Views | 8 | 3 hours |
| Public API | 5 | 1 hour |
| Testing | 6 | 2 hours |
| Integration | 4 | 1 hour |
| Packwerk | 4 | 30 min |
| Documentation | 4 | 1 hour |
| OpenSpec | 4 | 30 min |

**Total:** ~16 hours (2 work days)

---

## 🔗 Dependencies

**Requires:**
- ✅ Personas pack (already implemented)

**Required By:**
- ⏳ Clustering pack (Week 2)
- ⏳ AI Services (Week 3)
- ⏳ Content Strategy (Week 4)

---

## 🎬 Next Steps

1. **Review this proposal** - Ensure requirements match needs
2. **Approve for implementation** - Give go-ahead
3. **Implement sequentially** - Follow tasks.md in order
4. **Test with Sarah** - Import existing data
5. **Validate** - Run openspec validate --strict

**Ready to start?** Say "Let's implement Content Pillars"

---

## 📄 Files Created

```
openspec/changes/add-content-pillars/
├── proposal.md        (why, what, impact)
├── tasks.md           (59 implementation tasks)
├── specs/
│   └── content-pillars/
│       └── spec.md    (8 requirements, 15+ scenarios)
└── SUMMARY.md         (this file)
```

**Validation:**
```bash
$ openspec validate add-content-pillars --strict
Change 'add-content-pillars' is valid
```

**OpenSpec Status:**
```bash
$ openspec list | grep content-pillars
add-content-pillars                    0/59 tasks
```

---

