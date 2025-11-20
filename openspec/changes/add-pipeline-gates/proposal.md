# Change: Add Pipeline Step Approval Gates

## Why

The current automatic progression from step to step creates exponential growth (2→4→8→16→32) and lacks human control over quality filtering. This leads to:
- Wasted compute generating children from low-quality parents
- No checkpoint to evaluate quality before committing to next generation
- Inability to prune bad branches until after they've already spawned children

By adding manual approval gates with ELO-based filtering, users can:
- Inspect quality at each step before advancing
- Only advance the best N candidates to next step
- Control exponential growth (3→3→3 instead of 3→9→27)
- Make informed decisions about which lineages to pursue

## What Changes

- **Per-Run-Step Approval Model**: New `PipelineRunStep` join table tracks approval state per run per step
- **Approval Gates**: Steps must be manually approved before candidates can advance to next step
- **ELO-based Filtering**: When approving, only top-K ranked candidates become eligible parents
- **Tunable Parameters**: Separate N (candidates to generate) and K (candidates to advance)
- **Approval UI**: Dashboard shows approval status and allows one-click approval with preview
- **SelectNextJob Integration**: Job selection respects gates and only uses top-K candidates as parents

## Impact

- Affected specs: `pipeline-gates` (new capability), `job-orchestration` (modified)
- Affected code:
  - New model: `PipelineRunStep` (join table)
  - Modified: `SelectNextJob` command (add gate checks and top-K filtering)
  - New controller: `PipelineRunStepsController` for approval actions
  - Modified: Run dashboard UI to show approval states
  - New configuration: `JobOrchestrationConfig` (add N and K parameters)
- Database: New `pipeline_run_steps` table
- Behavior change: Runs will pause at each step until manually approved (breaking change)
- Migration path: Existing runs can be auto-approved for backward compatibility

## Breaking Changes

- **Existing runs will stall** unless auto-approved or migrated
- **SelectNextJob behavior changes** to respect gates
- **Exponential growth stops** - only top-K candidates advance

## Migration Strategy

1. Create `pipeline_run_steps` table
2. Auto-approve all existing PipelineRunSteps for active runs
3. Deploy code with gate enforcement enabled immediately
4. Existing runs continue normally (all steps auto-approved)
5. New runs require manual approval starting at Step 2
