# NSFW Content Gate — Tasks

## 1. Implementation

- [x] 1.1 Download `Falconsai/nsfw_image_detection` to `/mnt/fscache/essdee/nsfw-gate/` (verified: 9 files, loads in ComfyUI venv)
- [x] 1.2 Add `bin/nsfw_gate.py` — CPU-only ViT classification CLI, JSON per image
- [x] 1.3 Add `Growth::NsfwGate` service (fail-closed, ENV-tunable, 90s timeout)
- [x] 1.4 Wire gate into `Growth::ContentGenerator#generate_one` before photo import
- [x] 1.5 Rejection logging via `Growth::Decision` (`nsfw_rejected` action)
- [x] 1.6 Calibrate threshold on real renders (clean ≈0.03, NSFW 0.92–0.9999; default 0.5 has clear margin)

## 2. Verification

- [x] 2.1 CLI classifies real renders (clean/reject samples verified by eye)
- [x] 2.2 `Growth::NsfwGate` Ruby service: accept, reject, missing-file cases + 4 RSpec cases (fail-closed)
- [x] 2.3 Scan existing queue: 13/14 scheduled posts flagged → purged 13 (kept 1 clean), 13 `nsfw_purge` decisions logged
- [ ] 2.4 End-to-end render → gate → queue test (optional, needs a real 5–10 min render; skip unless requested)

## 3. Governance

- [x] 3.1 OpenSpec proposal validated (`openspec validate add-nsfw-gate --strict`)
- [x] 3.2 Commit + push (single commit, harness + B2 + gate per Tim)
- [x] 3.3 Update turbo-carnival-development skill with gate runbook