# Change: Add ComfyUI Integration

## Why
We need to integrate with ComfyUI to actually execute the AI image generation jobs. The system has the intelligence to select which job to run next and build the payload, but needs a way to send jobs to ComfyUI, monitor their execution, and process the results. This completes the autonomous workflow loop.

## What Changes
- Create new `comfyui` pack for external API integration
- Implement `SubmitJob` command to send workflow to ComfyUI API
- Implement `PollJobStatus` command to check job completion
- Implement `ProcessJobResult` command to save images and create ImageCandidate records
- Add ComfyUI API client with HTTP communication
- Add job tracking for in-flight jobs
- Handle success, failure, and retry scenarios

## Impact
- Affected specs: `comfyui-integration` (new capability)
- Affected code:
  - New pack: `packs/comfyui/`
  - New commands: `SubmitJob`, `PollJobStatus`, `ProcessJobResult`
  - New API client for HTTP communication
  - Integration with job_orchestration and pipeline packs
  - Async job processing (background workers)
