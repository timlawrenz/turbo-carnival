## 1. Database Migration
- [ ] 1.1 Create `pipeline_run_steps` table with columns:
  - `pipeline_run_id` (references pipeline_runs)
  - `pipeline_step_id` (references pipeline_steps)
  - `approved` (boolean, default: false)
  - `approved_at` (datetime, nullable)
  - `top_k_count` (integer, default: 3)
  - timestamps
- [ ] 1.2 Add unique index on `[pipeline_run_id, pipeline_step_id]`
- [ ] 1.3 Backfill existing runs: auto-approve all steps with top_k_count = N

## 2. Models
- [ ] 2.1 Create `PipelineRunStep` model
- [ ] 2.2 Add `has_many :pipeline_run_steps` to PipelineRun
- [ ] 2.3 Add `has_many :pipeline_run_steps` to PipelineStep
- [ ] 2.4 Add `PipelineRun#step_approved?(step)` helper method
- [ ] 2.5 Add `PipelineRun#approve_step!(step, top_k:)` method
- [ ] 2.6 Add `PipelineRunStep#top_k_candidates` query method
- [ ] 2.7 Add validation: `top_k_count >= 1`
- [ ] 2.8 Add validation: `approved_at` required if `approved == true`

## 3. Configuration
- [ ] 3.1 Add `JobOrchestrationConfig.default_top_k` (default: 3)
- [ ] 3.2 Update `max_children_per_node` documentation to clarify N vs K

## 4. Backend - SelectNextJob Changes
- [ ] 4.1 Modify `find_eligible_parents` to filter by approval
- [ ] 4.2 Add `in_top_k?(candidate)` method to check if candidate can advance
- [ ] 4.3 Update `work_on_run` to check if step is approved before using parents
- [ ] 4.4 Add `:waiting_for_approval` mode when run is blocked
- [ ] 4.5 Update logging to indicate when gates block progression

## 5. Backend - PipelineRunStepsController
- [ ] 5.1 Create `PipelineRunStepsController#show` - preview approval
- [ ] 5.2 Create `PipelineRunStepsController#approve` - approve step with K
- [ ] 5.3 Add validation: cannot approve if candidates still generating
- [ ] 5.4 Add validation: cannot approve if previous step unapproved
- [ ] 5.5 Return JSON with top-K candidates for preview

## 6. Backend - PipelineRun Lifecycle
- [ ] 6.1 Add `after_create` callback to auto-create PipelineRunSteps
- [ ] 6.2 Auto-approve Step 1 (order=1) on run creation
- [ ] 6.3 Leave all other steps unapproved by default

## 7. Frontend - Run Dashboard Updates
- [ ] 7.1 Show approval status badge for each step
- [ ] 7.2 Add "Approve Step X" button for unapproved steps with candidates
- [ ] 7.3 Show "Waiting for Step X approval" for blocked steps
- [ ] 7.4 Show "✅ Approved (3/5 advancing)" for approved steps
- [ ] 7.5 Add tooltip explaining what "3/5 advancing" means

## 8. Frontend - Approval Preview Modal
- [ ] 8.1 Create modal component showing candidates sorted by ELO
- [ ] 8.2 Highlight top-K candidates as "Will advance"
- [ ] 8.3 Show remaining candidates as "Will not advance"
- [ ] 8.4 Add slider/input to adjust K value
- [ ] 8.5 Show warning if vote_count < 5 for any candidate
- [ ] 8.6 Add "Approve with K=X" button
- [ ] 8.7 Add "Cancel" button to close without approving
- [ ] 8.8 Show preview updates in real-time as K changes

## 9. Frontend - Gallery/Voting Integration
- [ ] 9.1 Add badge to candidates showing approval status:
  - ✅ "Advancing to next step"
  - ⏸️ "Not advancing (below top-K)"
  - ❌ "Rejected"
- [ ] 9.2 Filter gallery to show "Advancing only" option
- [ ] 9.3 Update voting interface to show approval status

## 10. Tests - Models
- [ ] 10.1 Test `PipelineRunStep` creation with valid attributes
- [ ] 10.2 Test uniqueness constraint on `[run_id, step_id]`
- [ ] 10.3 Test `top_k_candidates` returns correct candidates sorted by ELO
- [ ] 10.4 Test `PipelineRun#approve_step!` updates approval state
- [ ] 10.5 Test auto-approval of Step 1 on run creation
- [ ] 10.6 Test validation: `top_k_count >= 1`

## 11. Tests - SelectNextJob
- [ ] 11.1 Test respects approval state
- [ ] 11.2 Test unapproved step blocks child generation
- [ ] 11.3 Test approved step with K=3 only uses top 3 as parents
- [ ] 11.4 Test `:waiting_for_approval` mode when blocked
- [ ] 11.5 Test global top-K filtering (not per-parent)
- [ ] 11.6 Test K > candidate count approves all available

## 12. Tests - Controller
- [ ] 12.1 Test `PipelineRunStepsController#show` returns candidate preview
- [ ] 12.2 Test `approve` action updates approval state
- [ ] 12.3 Test cannot approve if in-flight jobs exist
- [ ] 12.4 Test cannot approve twice
- [ ] 12.5 Test approval with custom K value

## 13. Tests - Integration
- [ ] 13.1 Full flow: Create run → Vote → Approve Step 1 → Generate Step 2 → Approve Step 2 → etc.
- [ ] 13.2 Test multi-run isolation (Run A approval doesn't affect Run B)
- [ ] 13.3 Test tied ELO scores in top-K selection
- [ ] 13.4 Test N=5, K=2 configuration

## 14. Documentation
- [ ] 14.1 Update README with approval gate workflow
- [ ] 14.2 Document N vs K configuration
- [ ] 14.3 Add migration guide for existing users
- [ ] 14.4 Document feature flag usage
- [ ] 14.5 Add troubleshooting: "Why is my run stuck?"

## 15. Migration Script
- [ ] 15.1 Create `PipelineRunStep` records for all existing runs
- [ ] 15.2 Auto-approve all steps for existing active runs
- [ ] 15.3 Set `top_k_count = max_children_per_node` (no filtering for existing)
- [ ] 15.4 Log summary: "Auto-approved X steps for Y runs"
- [ ] 15.5 Add rollback plan

## 16. UI Polish
- [ ] 16.1 Add icons for approval states (✅ ⏸️ 🔒 🔄)
- [ ] 16.2 Add progress bar showing approved vs total steps
- [ ] 16.3 Add "Approve All Remaining" bulk action
- [ ] 16.4 Add keyboard shortcut for approval (A key)
- [ ] 16.5 Add confetti/celebration on final step approval 🎉

## 17. Deployment
- [ ] 17.1 Run migration with backfill
- [ ] 17.2 Deploy code changes
- [ ] 17.3 Verify existing runs continue normally
- [ ] 17.4 Test new run creation requires approval
- [ ] 17.5 Monitor for stalled runs
- [ ] 17.6 Document new approval workflow

## Optional Enhancements (Future)
- [ ] Auto-approve based on ELO threshold (e.g., if all candidates > 1100)
- [ ] Email notifications when approval needed
- [ ] Approval by multiple users (voting/consensus)
- [ ] Undo approval (with cascade delete of children)
- [ ] Export approval history report
- [ ] Approval templates (save K configurations per pipeline)
