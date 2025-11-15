## 1. Update Configuration
- [x] 1.1 Change default `MAX_CHILDREN_PER_NODE` from 5 to 2 in `JobOrchestrationConfig`
- [x] 1.2 Add documentation about breadth-first strategy in comments

## 2. Update SelectNextJob Logic
- [x] 2.1 Remove or disable "triage-right" fallback logic (lines 115-131)
- [x] 2.2 Ensure breadth-first filling enforces N candidates per step before advancing
- [x] 2.3 Verify refill behavior when candidates are rejected
- [x] 2.4 Update logging to reflect breadth-first strategy

## 3. Testing
- [x] 3.1 Test with N=2: verify each step fills to 2 candidates before advancing
- [x] 3.2 Test rejection flow: verify rejected candidates trigger refill
- [x] 3.3 Test multi-pipeline scenario
- [x] 3.4 Verify in-flight job limiting still works

## 4. Documentation
- [x] 4.1 Update README or docs to explain breadth-first strategy
- [x] 4.2 Document ENV variables for configuration
