# Change: Add NSFW Content Gate

**Status:** Proposed
**Created:** 2026-08-22

## Summary

Add a third-party NSFW filter (Falconsai/nsfw_image_detection, a ViT-base
image classifier from Hugging Face) that runs on every freshly rendered image
**before** it is accepted into the photo library / scheduled-post queue. Any
image classified as NSFW is rejected: it never becomes a `ContentPillars::Photo`,
never gets a caption, and never gets scheduled. Every rejection is recorded in
the `Growth::Decision` audit log so the loop stays auditable.

## Why

The turbo-one-step render flow has been drifting into undergarment/lingerie
content (verified: 13 of 14 recent renders score >0.92 NSFW; 13 of 14
currently-scheduled queue posts fail the gate). That content risks the persona's
Instagram account (community-guideline strikes) and is off-brand anyway. The
harness needs a deterministic, external, content-agnostic gate before any image
is accepted into the queue — a human review can't inspect every render, and
prompt/seed drift happens autonomously.

## What Changes

- New service `Growth::NsfwGate` (in `packs/growth_harness`) that shells out to
  a small Python classifier and returns `safe`/`nsfw_score`/`label`.
- New script `bin/nsfw_gate.py` — Hugging Face model inference on CPU, reusing
  the existing ComfyUI venv (`torch 2.12 + transformers 5.9`), so no new
  Python environment or model runtime is installed.
- Model: `Falconsai/nsfw_image_detection` (Apache-2.0, ~37M downloads),
  downloaded at first setup to `/mnt/fscache/essdee/nsfw-gate/`.
- `Growth::ContentGenerator#generate_one` runs the gate between render
  completion and photo import; on rejection it records an `nsfw_rejected`
  decision and returns a failure the cadence engine logs.
- **Fail-closed**: any gate error (missing model, missing python, timeout) also
  rejects the image — never silently admit unmoderated content.
- Config knobs via ENV: `NSFW_MODEL_DIR`, `NSFW_PYTHON`, `NSFW_THRESHOLD`
  (default 0.5), `NSFW_GATE_DISABLED=1` emergency bypass.

No breaking changes — the gate only ever *blocks* the existing path.

## Impact

- Affected specs: `growth-harness` (MODIFIED — new requirement)
- Affected code:
  - `packs/growth_harness/app/services/growth/nsfw_gate.rb` (new)
  - `packs/growth_harness/app/services/growth/content_generator.rb` (gate + rejection logging)
  - `bin/nsfw_gate.py` (new)
- External: `Falconsai/nsfw_image_detection` model (~340 MB, local download)