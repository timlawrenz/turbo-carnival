## Context

Pipeline runs currently generate images in exponential tree growth (N children per parent). This is wasteful when low-quality parents spawn children before being rejected. The system needs human checkpoints to evaluate quality and prune branches before further generation.

The approval gate system provides manual control points where users can:
1. Review all candidates at a step
2. See ELO rankings
3. Approve progression, filtering to only top-K candidates
4. Or reject and abandon the run

## Goals

- Add manual approval gates between pipeline steps
- Filter to top-K ELO candidates when advancing
- Provide clear UI showing approval state
- Allow independent N (generate count) and K (advance count) tuning
- Block job generation past unapproved steps
- Track approval history per run per step

## Non-Goals

- Automatic approval based on ELO thresholds (future enhancement)
- Approval by multiple users / voting (future enhancement)
- Reverting approvals (if you want different results, create new run)
- Cross-run dependencies (runs remain independent)
- Approving individual candidates (approve whole step or nothing)

## Decisions

### Decision: PipelineRunStep Join Table
Create a join table between PipelineRun and PipelineStep to track per-run approval state.

**Rationale:**
- Runs progress independently (Run A at Step 3, Run B at Step 1)
- Same pipeline used as template for multiple runs
- Need to track when/who approved
- Allows per-run configuration of K value

**Alternatives considered:**
- Add `approved_steps` JSONB to PipelineRun: Harder to query, no timestamps
- Add `requires_approval` to PipelineStep: Not per-run, doesn't track history

### Decision: Global Top-K Filtering (Not Per-Parent)
When approving a step with 6 candidates from 2 parents, the global top-3 advance regardless of parent.

**Example:**
```
Step 2 candidates:
- Parent A → Child A1 (ELO 1200), A2 (1100), A3 (1000)
- Parent B → Child B1 (ELO 1150), B2 (1050), B3 (950)

After approval with K=3:
- A1, B1, A2 become eligible parents (global top 3)
- A3, B2, B3 cannot spawn children
```

**Rationale:**
- Maximizes quality of next generation
- Achieves the goal of pruning low-quality branches
- Simple to explain and implement

**Alternatives considered:**
- Top-K per parent: Doesn't reduce growth, defeats purpose
- Hybrid (top-K global with min 1 per parent): More complex, less effective

### Decision: Separate N and K Configuration
Allow independent tuning of N (candidates to generate) and K (candidates to advance).

**Example configurations:**
- N=5, K=3: Generate 5, advance best 3 (exploration mode)
- N=3, K=3: Generate 3, advance all if approved (quality mode)
- N=3, K=1: Generate 3, advance only best (aggressive pruning)

**Rationale:**
- Different steps may need different strategies
- User requested ability to tune independently
- Minimal complexity cost

**Defaults:**
- N=3 (JobOrchestrationConfig.max_children_per_node)
- K=3 (PipelineRunStep.top_k_count, per approval)

### Decision: Approval is One-Way (No Un-Approval)
Once a step is approved, it cannot be un-approved.

**Rationale:**
- Simpler state machine
- Avoids questions like "what happens to children that were already generated?"
- If user wants different results, create new run with different parameters

**Alternatives considered:**
- Allow un-approval: Complex, confusing UX, orphaned work

### Decision: Block Job Selection, Not Generation
`SelectNextJob` will skip parents from unapproved steps. Jobs already in queue will complete normally.

**Rationale:**
- Existing jobs (submitted, running) should complete
- Only prevent *new* jobs from being selected
- Avoids wasting work already in progress

### Decision: Auto-Approve Step 1 (Base Generation)
The first step of every run is automatically approved on creation.

**Rationale:**
- Nothing to gate (no parents to filter)
- User explicitly created the run (implicit approval)
- Avoids extra click for obvious case

## Risks / Trade-offs

### Risk: User forgets to approve, run stalls
**Mitigation:**
- Clear UI showing "Awaiting Approval" status
- Dashboard highlights runs needing attention
- Consider email/notification in future

### Risk: Not enough votes to establish meaningful ELO
If user approves with only 1 vote per candidate, ELO differences are minimal.

**Mitigation:**
- Show ELO confidence in UI ("Only 2 votes, rankings may change")
- Recommend minimum vote count before approval
- Allow approval anyway (user's choice)

### Risk: All top-K from same parent (loss of diversity)
With global filtering, all top candidates could be siblings.

**Acceptance:**
- This is working as designed (quality over diversity)
- User can inspect rankings before approving
- If concerned, can set K higher or reject and re-run

### Risk: Breaking change to existing runs
Runs in progress will stall at next step without approval.

**Mitigation:**
- Migration script auto-approves all steps for existing runs
- Feature flag to enable gates (default: off for transition period)
- Clear release notes

## Migration Plan

### Phase 1: Database & Auto-Approval
1. Create `pipeline_run_steps` table
2. Add `approved` boolean (default false)
3. Backfill: auto-approve all steps for existing runs
4. Add `top_k_count` set to N (no filtering for existing runs)

### Phase 2: Code Changes
1. Add PipelineRunStep model with associations
2. Modify SelectNextJob to respect gates
3. Add PipelineRunStepsController for approval actions
4. Update run creation to auto-approve Step 1

### Phase 3: UI
1. Show approval status on run dashboard
2. Add approval preview modal
3. Add approval badges to gallery/voting

### Phase 4: Deploy
1. Run migration (auto-approves existing runs)
2. Deploy code
3. Existing runs continue normally
4. New runs require approval starting at Step 2

## Open Questions

### Should K be configurable per-step or per-run?
**Current design:** Per-run (PipelineRunStep.top_k_count)

**Alternative:** Per-step (PipelineStep.default_top_k)

**Recommendation:** Per-run for now, can add per-step defaults later.

### What if K > number of candidates?
**Example:** Step has 2 candidates, user approves with K=3

**Options:**
1. Approve all 2 (K is a maximum, not required)
2. Show error "Not enough candidates"

**Recommendation:** Option 1 (K is max, approve all available)

### Show only approved candidates in gallery?
Or show all with visual indication of approved/filtered?

**Recommendation:** Show all with badges:
- ✅ Approved (top-K)
- ⏸️ Not advancing (below K)
- ❌ Rejected (manually killed)

### Allow changing K after approval?
**Example:** User approved with K=3, wants to change to K=5

**Recommendation:** No. Create new run instead.
