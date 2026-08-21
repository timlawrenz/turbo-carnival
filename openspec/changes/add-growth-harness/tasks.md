# Tasks: Add Growth Harness

## 1. Implementation
- [ ] 1.1 Create migration for growth_goals, growth_snapshots, growth_decisions
- [ ] 1.2 Add Growth::Goal, Growth::Snapshot, Growth::Decision models
- [ ] 1.3 Add Instagram::Client#followers_count via Graph API
- [ ] 1.4 Add Growth::MetricsCollector (follower snapshot capture)
- [ ] 1.5 Add Growth::CadenceEngine (schedule top-up)
- [ ] 1.6 Add Growth::StrategyBrain (periodic review + strategy adjustment)
- [ ] 1.7 Add rake tasks (growth:sync_cadence, snapshot_followers, review_strategy, status, run_all)
- [ ] 1.8 Add dashboard controller/view/route at /growth
- [ ] 1.9 Add bin/growth_harness.sh + crontab entry

## 2. Verification
- [ ] 2.1 Run migration and boot check
- [ ] 2.2 Run growth:status rake task
- [ ] 2.3 Run growth:sync_cadence and confirm queue top-up
- [ ] 2.4 Run growth:review_strategy and confirm decision log

## 3. Tests
- [ ] 3.1 Unit specs for StrategyBrain trajectory math
- [ ] 3.2 Spec for CadenceEngine top-up logic