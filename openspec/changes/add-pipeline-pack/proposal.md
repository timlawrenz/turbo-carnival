# Change: Add Pipeline Pack with Core Data Models

## Why
The system needs a domain-specific pack to manage AI image generation pipelines. This pack will encapsulate the core data models (Pipeline, PipelineStep, ImageCandidate) and business logic for the multi-stage workflow orchestration, providing a clear boundary for pipeline-related functionality.

## What Changes
- Create new `packs/pipeline` pack using Packwerk
- Add `Pipeline` model to represent reusable pipeline configurations
- Add `PipelineStep` model to define stages within a pipeline
- Add `ImageCandidate` model to track image nodes in the generation tree
- Implement state machine for `ImageCandidate` status transitions
- Add database migrations for all three models
- Configure pack dependencies and privacy boundaries

## Impact
- Affected specs: `pipeline` (new capability)
- Affected code: 
  - New pack created at `packs/pipeline/`
  - New models: `Pipeline`, `PipelineStep`, `ImageCandidate`
  - Database schema changes via migrations
  - Packwerk configuration updated
