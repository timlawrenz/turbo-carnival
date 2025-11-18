# Change: Extract Prompt and Run Name from Variables to Dedicated Columns

## Why
Currently, `prompt` and `run_name` are stored in the JSONB `variables` column on `PipelineRun`. This makes them:
- Harder to query and index efficiently
- Inconsistent (sometimes in `name`, sometimes in `variables['run_name']`)
- Less discoverable in the schema
- More complex to access (requires JSONB queries or fallback logic)

Since `prompt` and `run_name` are core attributes used across the system (not arbitrary metadata), they should be first-class database columns.

## What Changes
- Add `prompt` column to `pipeline_runs` table (string, nullable)
- Move `run_name` logic to use existing `name` column exclusively (already exists)
- Create migration to backfill data from `variables` to new column
- Update all code that reads `variables['prompt']` or `variables['run_name']` to use the new columns
- Update job payload building to merge prompt back into variables for ComfyUI compatibility
- Remove `prompt` and `run_name` from `variables` JSONB column after migration

## Impact
- Affected specs: pipeline, job-orchestration
- Affected code:
  - Migration: Add prompt column and backfill
  - Models: PipelineRun
  - Commands: BuildJobPayload, CreatePipelineRun
  - Views: All views using `variables['run_name']` or `variables['prompt']`
  - Tests: Update specs referencing variables hash
- **BREAKING**: Code that directly accesses `variables['prompt']` or `variables['run_name']` must be updated
