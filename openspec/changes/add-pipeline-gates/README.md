# Pipeline Gates - Visual Guide

## Before Gates (Current System)

```
Run A: "Cyberpunk Portrait"
═══════════════════════════════════════════════════════════

Step 1: Base Gen     Step 2: Face Fix      Step 3: Hand Fix
[N=2 per parent]     [N=2 per parent]      [N=2 per parent]
                     
    A1 ─────────────→ A1a ────────────────→ A1a1
    │                  A1b                   A1a2
    │                                        A1b1
    │                                        A1b2
    │
    A2 ─────────────→ A2a ────────────────→ A2a1
                       A2b                   A2a2
                                             A2b1
                                             A2b2

Growth: 2 → 4 → 8 → 16 → 32 (exponential!)
Problem: Low-quality parents (A2) waste compute spawning children
```

## After Gates (Proposed System)

```
Run A: "Cyberpunk Portrait"
═══════════════════════════════════════════════════════════

Step 1: Base Gen          Step 2: Face Fix        Step 3: Hand Fix
[Generate N=3]            [Generate N=3]          [Generate N=3]
[✅ Auto-approved]        [⏸️ Awaiting approval]  [🔒 Blocked]

    A1 (ELO 1200) ────→  A1a (ELO 1250)
    A2 (ELO 1100)         A1b (ELO 1180)
    A3 (ELO 1000)         A1c (ELO 1150)
                          
                          A2a (ELO 1120)
                          A2b (ELO 1080)
                          A2c (ELO 1050)
                          
                          A3a (ELO 1020)
                          A3b (ELO 980)
                          A3c (ELO 950)

User action: APPROVE STEP 2 with K=3
─────────────────────────────────────────────────────────

Step 2 after approval:    Step 3 generation
[✅ Approved, K=3]        [Generate N=3 per top-K parent]

✅ A1a (1250) ───────────→ A1a1
✅ A1b (1180)              A1a2
✅ A2a (1120)              A1a3
                          
⏸️ A1c (1150)              A1b1
⏸️ A2b (1080)              A1b2
⏸️ A2c (1050)              A1b3
⏸️ A3a (1020)              
⏸️ A3b (980)               A2a1
⏸️ A3c (950)               A2a2
                           A2a3

Only top 3 globally advance → 3 parents → 9 candidates at Step 3

Growth: 3 → 9 → 9 → 9 (controlled!)
Benefit: Low-quality branches pruned before wasting compute
```

## Approval UI Flow

```
┌─────────────────────────────────────────────────────────┐
│ Run Dashboard: "Cyberpunk Portrait"                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ ✅ Step 1: Base Generation                              │
│    Status: Approved (3/3 advancing)                     │
│    Candidates: A1 (1200), A2 (1100), A3 (1000)          │
│                                                          │
│ ⏸️  Step 2: Face Fix                                     │
│    Status: Awaiting Approval (9 candidates ready)       │
│    [ Preview Approval ]  [ Vote More ]                  │
│                                                          │
│ 🔒 Step 3: Hand Fix                                     │
│    Status: Blocked (Step 2 unapproved)                  │
│                                                          │
└─────────────────────────────────────────────────────────┘

User clicks "Preview Approval" on Step 2:

┌─────────────────────────────────────────────────────────┐
│ Approve Step 2: Face Fix                                │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ How many candidates should advance? [3] ◄─ K slider     │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                                          │
│ ✅ WILL ADVANCE (Top 3)                                 │
│ ┌──────────────────────────────────────────────────┐   │
│ │ [Image] A1a                      ELO: 1250  #1   │   │
│ │ [Image] A1b                      ELO: 1180  #2   │   │
│ │ [Image] A2a                      ELO: 1120  #3   │   │
│ └──────────────────────────────────────────────────┘   │
│                                                          │
│ ⏸️ WILL NOT ADVANCE (Below K=3)                         │
│ ┌──────────────────────────────────────────────────┐   │
│ │ [Image] A1c                      ELO: 1150  #4   │   │
│ │ [Image] A2b                      ELO: 1080  #5   │   │
│ │ [Image] A2c                      ELO: 1050  #6   │   │
│ │ [Image] A3a                      ELO: 1020  #7   │   │
│ │ [Image] A3b                      ELO: 980   #8   │   │
│ │ [Image] A3c                      ELO: 950   #9   │   │
│ └──────────────────────────────────────────────────┘   │
│                                                          │
│ ⚠️ Some candidates have fewer than 5 votes.             │
│    Rankings may change with more voting.                │
│                                                          │
│ [ Cancel ]           [ Approve with K=3 ]               │
└─────────────────────────────────────────────────────────┘

User clicks "Approve with K=3":
→ PipelineRunStep updated: approved=true, top_k_count=3
→ Only A1a, A1b, A2a can become parents
→ SelectNextJob will generate 3 children for each (9 total at Step 3)
```

## Configuration Examples

### Example 1: Aggressive Pruning (N=5, K=1)
```
Generate 5 per parent → Only best 1 advances
Step 1: 3 base images
Step 2: 15 candidates (3 parents × 5 each) → approve K=1 → 1 advances
Step 3: 5 candidates (1 parent × 5) → approve K=1 → 1 advances
Step 4: 5 candidates (1 parent × 5) → approve K=1 → DONE

Total: 3 + 15 + 5 + 5 = 28 images
Result: Very selective, high quality, low diversity
```

### Example 2: Balanced (N=3, K=3)
```
Generate 3 per parent → All can advance if quality is good
Step 1: 3 base images
Step 2: 9 candidates (3 parents × 3 each) → approve K=3 → 3 advance
Step 3: 9 candidates (3 parents × 3 each) → approve K=3 → 3 advance
Step 4: 9 candidates (3 parents × 3 each) → approve K=3 → DONE

Total: 3 + 9 + 9 + 9 = 30 images
Result: Consistent quality bar, moderate diversity
```

### Example 3: Exploration (N=5, K=3)
```
Generate 5 per parent → Top 3 advance
Step 1: 3 base images
Step 2: 15 candidates (3 parents × 5 each) → approve K=3 → 3 advance
Step 3: 15 candidates (3 parents × 5 each) → approve K=3 → 3 advance
Step 4: 15 candidates (3 parents × 5 each) → approve K=3 → DONE

Total: 3 + 15 + 15 + 15 = 48 images
Result: More exploration, prune 40% at each gate
```

## Key Concepts

### N (Max Children Per Node)
- How many candidates to GENERATE per parent
- Set in `JobOrchestrationConfig.max_children_per_node`
- Default: 3
- Determines generation cost

### K (Top K to Advance)  
- How many candidates can ADVANCE to next step
- Set per approval in `PipelineRunStep.top_k_count`
- Default: 3
- Determines filtering aggressiveness

### Global Top-K (Not Per-Parent)
- Rankings are computed globally across all candidates at a step
- Example: If Parent A's children dominate top-K, Parent B's children may be filtered out
- This maximizes quality but may reduce diversity

### Per-Run Approval
- Each PipelineRun has its own approval state
- Run A can be at Step 3 while Run B is at Step 1
- Approvals are independent and don't affect other runs

## Migration Path

### Phase 1: Database & Backfill
- Create `pipeline_run_steps` table
- Backfill existing runs with auto-approvals
- All existing runs continue working

### Phase 2: Code & UI
- Add approval models and controllers
- Show approval status on dashboard
- Add approval preview modal

### Phase 3: Deploy
- Run migration
- Deploy code
- Gates are immediately active for new runs
- Existing runs unaffected (already approved)
