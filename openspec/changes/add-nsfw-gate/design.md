# NSFW Content Gate — Design

## Context

The turbo-carnival harness renders images autonomously (turbo-one-step on the
RTX 4090) and schedules them for Instagram. Renders drift: the current flow's
prompt/scene sampling produces lingerie/undergarment images at a high rate
(13/14 recent renders). No moderation step exists between "render completes"
and "post is scheduled". This gate adds a deterministic third-party content
check at that single choke point: `Growth::ContentGenerator#generate_one`.

## Goals / Non-Goals

- Goals:
  - Block NSFW renders before photo import / queueing, every time, deterministically.
  - Auditable: every rejection lands in `growth_decisions` with reason + file path.
  - Zero new heavyweight infra: reuse what's on the box.
- Non-Goals:
  - Retroactively filtering the existing library (separate, human-decision task).
  - Prompt/seed fixes to stop drift at the source (separate pipeline change).
  - Human-in-the-loop review UI.

## Decisions

- **Decision: HF model `Falconsai/nsfw_image_detection`** — ViT-base fine-tuned
  for NSFW/normal, Apache-2.0, the de-facto standard HF NSFW classifier
  (~37.7M downloads). Alternatives considered: `AdamCodd/vit-base-nsfw-detector`
  (same architecture, less battle-tested), Yahoo `open_nsfw` (dated, Caffe),
  HF serverless Inference API (sends render bytes to Hugging Face — rejected:
  content privacy + rate limits + external dependency at post time).
- **Decision: Reuse ComfyUI's venv python** (`/mnt/fscache/essdee/ComfyUI/venv/bin/python`,
  torch 2.12.0+cu130, transformers 5.9.0) instead of installing a new
  environment. Rationale: the pattern is already on the box, weights load in
  ~4 s from disk, and a dedicated venv would be a 2.5 GB torch install for one
  tiny classifier.
- **Decision: CPU-only inference** — ComfyUI is memory-tight on the 4090
  (~23/24 GB peak); a ViT at 224×224 takes <1 s on CPU at our volume
  (one image per generation cycle).
- **Decision: Fail closed.** A gate error (model missing, python missing,
  timeout) rejects the image. Unmoderated content must never slip through
  because the filter hiccupped. `NSFW_GATE_DISABLED=1` exists as an explicit
  emergency bypass.
- **Decision: Threshold 0.5 default** (NSFW probability ≥ 0.5 → reject),
  tunable via `NSFW_THRESHOLD`. Calibration on real renders: clean portraits
  score ~0.03, lingerie renders 0.92–0.9999 — wide margin, no observed false
  positives.

## Risks / Trade-offs

- [ComfyUI venv changes could break the gate] → `NSFW_PYTHON` env override;
  classifier deps (torch/transformers/PIL) are core to that venv and stable.
- [False positives on swimwear/cleavage] → threshold is env-tunable; ViT shows
  clean margins on real data so far.
- [First-call latency] → module load ~4-6 s, then ~0.3 s/image; fine per
  render (renders take 5–10 min).
- [Gate stalls cadence when renders are predominantly NSFW] → by design:
  `cadence_blocked` decisions get logged; the hourly brain adapts.

## Migration Plan

- Deploy: ship `nsfw_gate.rb`, `bin/nsfw_gate.py`, ContentGenerator patch.
- Model already downloaded to `/mnt/fscache/essdee/nsfw-gate/nsfw_image_detection`.
- Rollback: set `NSFW_GATE_DISABLED=1` (no code revert needed) or revert the
  ContentGenerator patch.