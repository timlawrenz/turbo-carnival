# Change: Add Run Create Interface

## Why
Users cannot currently create new pipeline runs through the web interface. The RunsController only supports viewing existing runs (index, show) but has no create action. Users need a way to initiate new pipeline executions with custom variables and settings.

## What Changes
- Add `new` and `create` actions to RunsController
- Create form interface for run creation with pipeline selection, run name, variables, and target folder
- Add routes for run creation
- Implement GLCommand for run creation logic
- Add validation and error handling
- **Note:** Skipping authorization (Pundit) as this is a single-user interface

## Impact
- Affected specs: pipeline
- Affected code: RunsController, routes.rb, new view files
- New GLCommand: CreatePipelineRun
