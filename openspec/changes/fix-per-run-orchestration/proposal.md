# Change: Fix Job Orchestration to Work Per-Run Instead of Globally

## Why
The current implementation has a fundamental architectural flaw: it counts candidates globally across all active pipeline runs, but each run should be an independent generation process with its own breadth-first tree.

**Current broken behavior:**
- Run A: Step 1 has 1 candidate, Step 2 has 0 candidates (needs work!)
- Run B: Step 1 has 1 candidate, Step 2 has 2 candidates (complete)
- System sees: Step 1 has 2 total, Step 2 has 2 total → returns `:no_work` ❌

**Expected behavior:**
- Run A needs filling (Step 2 is incomplete)
- Run B is complete
- System should work on Run A

This affects:
1. Job selection (SelectNextJob counts globally)
2. Voting UI (shows candidates across runs, can't curate per-run)
3. Gallery (mixes candidates from different runs)

## What Changes

### Core Logic Changes
- **SelectNextJob**: Work on one run at a time, fill each run's steps to N before moving to next run
- **Run selection strategy**: Round-robin through active runs that have incomplete steps
- **Per-run breadth-first**: Each run maintains its own N candidates per step
- **Single job execution**: Only one ComfyUI job runs at a time; round-robin distributes work across runs
- **Implicit pausing**: Runs with all steps filled to N are automatically skipped in round-robin

### UI Changes
- **Voting interface**: Nested route `/runs/:run_id/vote` shows only that run's candidates
- **Gallery interface**: Nested route `/runs/:run_id/gallery` filters by run and step
- **Run dashboard**: New view at `/runs` showing all runs and their completion status
- **RESTful routes**: Proper nested resource hierarchy for runs → candidates

### Data Model (Optional)
- Consider adding `completion_percentage` to PipelineRun for easy tracking
- Track per-run statistics

## Impact
- Affected specs: `job-orchestration`
- Affected code:
  - `packs/job_orchestration/app/commands/select_next_job.rb` - Major refactor for per-run selection
  - `app/controllers/image_votes_controller.rb` - Change to nested routes
  - `app/controllers/gallery_controller.rb` - Change to nested routes
  - `config/routes.rb` - Complete restructure with nested resources
  - New: `app/controllers/runs_controller.rb` - Run management dashboard
- Breaking: **Yes** - All URLs change, fundamental job selection algorithm changes
- Migration: Update bookmarks, existing runs will work with new per-run logic
