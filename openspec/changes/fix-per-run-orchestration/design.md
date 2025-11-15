## Context

The current job orchestration system counts candidates globally across all active pipeline runs. This creates a fundamental mismatch: each PipelineRun represents a separate creative session (e.g., "Morning Gym Shoot", "Afternoon Cafe Shoot") that should maintain its own independent candidate tree.

**Current problem:**
- 3 runs active, each partially complete
- Global counting shows "2 candidates at Step 2" (1 from Run A, 1 from Run B)
- System thinks Step 2 is complete, but both runs are actually incomplete
- User can't curate Run A separate from Run B

**User expectation:**
- Each run is a distinct project
- Want to fill out Run A completely before or alongside Run B
- Want to vote on Run A's candidates without seeing Run B's candidates mixed in

## Goals / Non-Goals

**Goals:**
- Per-run job orchestration: Each run fills independently to N candidates per step
- Per-run UI filtering: Vote and browse candidates within a single run
- Run management: Dashboard to see all runs and their completion status
- Maintain breadth-first within each run: Still fill steps to N before advancing

**Non-Goals:**
- Cross-run comparisons or voting (comparing Run A's candidates vs Run B's)
- Automatic run prioritization based on quality/ELO (just round-robin for now)
- Merging runs or moving candidates between runs

## Decisions

### Decision: Round-Robin Run Selection
**What:** When multiple runs need work, cycle through them in round-robin order (by ID or creation time)
**Why:** Simple, fair, prevents one run from hogging resources
**How it works:**
1. Get list of active runs (status != 'completed')
2. For each run, check if any step has < N candidates
3. Runs with all steps filled to N are skipped (implicitly "paused")
4. Select first run that needs work (using modulo or last_worked_run_id tracking)
5. Work on that run until one job is submitted
6. Next invocation picks the next run in sequence

**Alternatives considered:**
- Priority-based (by creation time): Older runs first
- Random selection
- User-specified priority
**Trade-offs:** Round-robin is simplest to implement and reason about. Can add priority later if needed.

### Decision: Per-Run Breadth-First
**What:** Apply the same N=2 breadth-first strategy, but scoped to each run
**Why:** Maintains tree control while working independently per run
**Rationale:** The breadth-first strategy is sound, just needs to be per-run not global

### Decision: Nested RESTful Routes
**What:** Use nested routes to reflect the run → step → candidate hierarchy
**Why:** Makes URLs intuitive and self-documenting, clearly shows resource relationships
**Structure:**
```ruby
# Runs
/runs                           # List all runs
/runs/:id                       # Show specific run details
/runs/:id/complete             # Mark run as complete

# Voting (scoped to run)
/runs/:run_id/vote             # Vote within a specific run
/runs/:run_id/vote/reject/:id  # Reject candidate in run

# Gallery (scoped to run and step)
/runs/:run_id/gallery                    # Gallery for run (defaults to last step)
/runs/:run_id/gallery?step=2             # Gallery for specific step in run
/runs/:run_id/candidates/:id/reject      # Reject candidate in run

# Images (global, no run needed)
/images/:id                    # Serve candidate image
```

**Alternatives considered:**
- Flat routes with query params: `/vote?run_id=14` (less RESTful, harder to bookmark)
- Only run-level nesting: `/runs/:id/vote` (loses step context in gallery)

**Benefits:**
- URLs are bookmarkable and shareable
- Clear resource hierarchy: run contains candidates
- Standard Rails conventions (easier to maintain)
- Better for future API versioning

**Trade-offs:** 
- Slightly more verbose URLs
- Need to update all existing routes and views

### Decision: No Auto-Completion of Runs
**What:** Runs stay in "running" status until manually marked complete
**Why:** User may want to continue refining even when breadth-first is satisfied
**Migration:** User explicitly completes runs when satisfied with results

## Risks / Trade-offs

**Risk:** Starvation - one run never gets worked on
- Mitigation: Round-robin ensures fair distribution

**Risk:** User confusion about which run is being worked on
- Mitigation: Clear logging shows which run is selected
- Mitigation: Dashboard shows all runs and their status

**Trade-off:** More complex UI with run selector
- Benefit: Much better organization for multiple concurrent runs
- User must select run before voting/browsing (one extra click)

## Migration Plan

**For existing data:**
1. Runs 15 and 16 are incomplete (Step 1 has 1 candidate each)
2. Run 14 is partially complete
3. After deployment, system will work on each run independently
4. Manually complete unwanted runs via dashboard

**For users:**
1. Voting UI gets run selector (defaults to first active run)
2. Gallery UI gets run selector
3. New "Runs" dashboard to manage all runs

**Rollback:**
If needed, can revert to global counting, but will need to manually merge or complete runs

## Open Questions

**Q: Should we add a "pause run" status to skip it in round-robin?**
**A: No.** A run is implicitly "paused" when all its steps are filled to N candidates. The round-robin will naturally skip it and move to the next run that needs work. No explicit pause status needed.

**Q: Should we allow concurrent work on multiple runs (N jobs per run)?**
**A: No.** Hardware can only run one ComfyUI job at a time. Round-robin selects one job from run A, waits for completion, then selects one job from run B (if run B needs work). This distributes work fairly across runs while respecting hardware constraints.

**Q: Should completed runs be archived after X days?**
**A: No.** No automatic archival process for now. Runs stay in the database indefinitely. Manual cleanup can be added later if needed.
