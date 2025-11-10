# Change: Add Job Orchestration for Pipeline Execution

## Why
We need intelligent job selection logic that decides which ComfyUI job to run next. The system must prioritize finishing work (right-to-left through pipeline steps), use ELO-weighted raffle for candidate selection, and autonomously generate new base images when needed. This is the core algorithm that drives the autonomous workflow and ensures efficient GPU utilization.

## What Changes
- Create new `job_orchestration` pack with GLCommand pattern
- Implement `SelectNextJob` command using the right-to-left priority algorithm
- Add `JobOrchestrationConfig` for N (max children) and T (target leaf nodes)
- Implement ELO-weighted raffle selection within priority groups
- Handle autonomous deficit mode for base image generation
- Create structured job payload for ComfyUI integration
- Add `BuildJobPayload` command for variable substitution

## Impact
- Affected specs: `job-orchestration` (new capability)
- Affected code:
  - New pack: `packs/job_orchestration/`
  - New commands: `SelectNextJob`, `BuildJobPayload`
  - New configuration class: `JobOrchestrationConfig`
  - Integration with pipeline pack for data access
