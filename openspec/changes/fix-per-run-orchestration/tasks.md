## 1. Update SelectNextJob Logic
- [x] 1.1 Add run selection logic (pick which run to work on)
- [x] 1.2 Change candidate counting to be per-run instead of global
- [x] 1.3 Implement round-robin or priority-based run selection
- [x] 1.4 Update logging to show which run is being worked on
- [x] 1.5 Handle edge case: no active runs

## 2. Update Voting Interface
- [x] 2.1 Change route to `/runs/:run_id/vote`
- [x] 2.2 Update controller to load run from params
- [x] 2.3 Filter unvoted pairs by run
- [x] 2.4 Show run name and progress in header
- [x] 2.5 Add link back to run dashboard
- [x] 2.6 Update reject path to `/runs/:run_id/vote/reject/:id`

## 3. Update Gallery Interface
- [x] 3.1 Change route to `/runs/:run_id/gallery`
- [x] 3.2 Update controller to load run from params
- [x] 3.3 Filter candidates by run
- [x] 3.4 Show per-run step completion status
- [x] 3.5 Display run-specific stats
- [x] 3.6 Update reject path to `/runs/:run_id/gallery/reject/:id`

## 4. Create Run Dashboard and Routes
- [x] 4.1 Create RunsController with RESTful actions
- [x] 4.2 Add nested routes for runs, voting, and gallery
- [x] 4.3 Create runs/index view showing all runs
- [x] 4.4 Create runs/show view with run details (index shows all details)
- [x] 4.5 Display completion status per run
- [x] 4.6 Add "Complete run" action (POST /runs/:id/complete)
- [x] 4.7 Update root route to redirect to /runs

## 5. Update Tests
- [ ] 5.1 Update SelectNextJob specs for per-run behavior
- [ ] 5.2 Add tests for run selection logic
- [ ] 5.3 Update voting controller specs
- [ ] 5.4 Update gallery controller specs
- [ ] 5.5 Add runs controller specs

## 6. Documentation
- [ ] 6.1 Update README with per-run workflow
- [ ] 6.2 Document run selection strategy
- [ ] 6.3 Add examples of multi-run usage
