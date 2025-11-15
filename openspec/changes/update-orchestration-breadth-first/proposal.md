# Change: Update Job Orchestration to Strict Breadth-First Strategy

## Why
The current "triage-right" strategy creates too many branches too quickly, leading to unmanageable candidate trees (currently up to 5 children per node). A breadth-first approach with limited branching (N=2-3) will create more focused, manageable exploration of the image space while still allowing experimentation and ELO-based selection.

## What Changes
- Change default `MAX_CHILDREN_PER_NODE` from 5 to 2-3
- Enforce strict breadth-first: fill each pipeline step to N active candidates before advancing to next step
- Allow automatic refilling when candidates are rejected (maintain N active candidates per step)
- Remove or deprioritize the "triage-right" fallback behavior that pushes candidates deeper once minimums are met

## Impact
- Affected specs: `job-orchestration`
- Affected code: 
  - `packs/job_orchestration/app/commands/select_next_job.rb`
  - `packs/job_orchestration/app/services/job_orchestration_config.rb`
- Breaking: Yes - changes fundamental job selection strategy
- Deployment: Requires restarting Sidekiq workers and potentially clearing pending jobs
