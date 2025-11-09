# Change: Add Pipeline Runs and Step Variable Templating

## Why
Currently, Pipelines are reusable templates but we have no way to execute them with different inputs (prompts, parameters). We need to run the same pipeline structure (Base → Face → Hands → Upscale) 20+ times per day with different prompts ("at home", "at the gym", etc.). Each step needs to declare what variables it requires (original prompt, parent image path, etc.) so ComfyUI jobs can be built dynamically.

## What Changes
- Add `PipelineRun` model to track individual executions of a pipeline with specific inputs
- Add variable templating system for `PipelineStep` configuration
- Support step-level variable requirements (e.g., `needs_run_prompt`, `needs_parent_image`)
- Add `variables` JSONB column to store run-specific inputs (prompt, parameters)
- Update `ImageCandidate` to link to a `PipelineRun` instead of just `PipelineStep`

## Impact
- Affected specs: `pipeline` (modify existing capability)
- Affected code:
  - New model: `PipelineRun`
  - Modified: `ImageCandidate` (add `pipeline_run_id`)
  - Modified: `PipelineStep` (add variable requirement flags)
  - Database migrations for new model and schema changes
