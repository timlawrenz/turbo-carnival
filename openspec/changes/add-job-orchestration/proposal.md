# Change: Add Job Orchestration for Pipeline Execution

## Why
We need intelligent job selection logic that decides which ComfyUI job to run next. The system must prioritize finishing work (right-to-left through pipeline steps), use ELO-weighted raffle for candidate selection, and autonomously generate new base images when needed. This is the core algorithm that drives the autonomous workflow.

## What Changes
- Create new `job_orchestration` pack with GLCommand pattern
- Implement `SelectNextJob` command using the right-to-left priority algorithm
- Add configuration for `N` (max children per node) and `T` (target leaf nodes)
- Implement ELO-weighted raffle selection
- Handle autonomous deficit mode for base image generation
- Create job data structure for ComfyUI integration

## Impact
- Affected specs: `job-orchestration` (new capability)
- Affected code:
  - New pack: `packs/job_orchestration/`
  - New command: `SelectNextJob`
  - New configuration class for N and T parameters
  - Job construction logic using variable templating
