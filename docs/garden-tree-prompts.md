# Garden of Grace — Tree Growth Flipbook (28 frames, chained)

Photoreal "growing fruit tree in a terracotta pot" flipbook for the Garden of Grace
gamification feature. **28 frames** of the SAME tree maturing continuously, rendered as
transparent 3:4 portrait PNGs.

## Why chained image-to-image

Independent text-to-image per frame flickers — the pot, soil, camera and lighting jump
around. Instead this uses the studio "AI flipbook" approach: frame 00 is generated from
text, then every later frame is an **image-to-image edit of the previous frame** with a
small "grow a little more" instruction. The scene is carried forward; only the plant
changes.

## Models

| Pass | Model slug | Purpose |
|------|------------|---------|
| Frame 00 text2img | `google/nano-banana/text-to-image` | Seed/sprout starting point on cream background ($0.038/img) |
| Frames 01-27 edit | `google/nano-banana/edit` | Image+instruction → edited image, chained ($0.038/img) |
| Background removal | `wavespeed-ai/image-background-remover` | Transparent cutout (~$0.01/image) |

Default is **Google nano-banana (Gemini 2.5 Flash Image)** for both the base frame and the
chained edits — in testing it preserves the pot/soil/lighting far better across a long
chain than Flux Kontext Pro did (which degraded into a "plastic topiary" look after ~14
edits). nano-banana output is opaque, so the background-removal pass is still required.

Configurable: `--model` (frame 00), `--edit-model` (01-27). Payloads auto-adapt by slug:
a slug containing `nano-banana` uses `{prompt, images:[url], aspect_ratio, output_format}`
for edits (and `{prompt, aspect_ratio, output_format}` for the base); the Flux Kontext
family uses `{image, prompt, aspect_ratio, guidance_scale}`; flux-dev base uses
`{prompt, size, num_images, seed}`.

All calls use the WaveSpeed v3 REST API: `POST /api/v3/{model}` (Bearer auth) → poll
`data.urls.get` until `status == completed` → image URL at `data.outputs[0]`.

## File contract (do not rename)

Output folder: `assets/garden/tree/`
Files: `tree_00.png` … `tree_27.png` (zero-padded, in growth order), transparent RGBA PNG.

Chain bookkeeping lives in `assets/garden/tree/_chain/`:
- `chain_state.json` — maps frame index → the cream-background source URL (the input fed to
  the next frame's edit).
- `tree_NN_src.png` — local backup copy of each cream-background source (for debugging /
  manual cutout).

## Frame → maturity map

| Frames | Stage |
|--------|-------|
| 00-02 | Seed (seed in soil → first green tip) |
| 03-05 | Sprouting (cotyledons → short stem, few leaves) |
| 06-08 | Growing (bushier, many leaves, woody base forming) |
| 09-11 | Blossoming (leaves + first blossoms) |
| 12-14 | Bearing fruit (blossoms → first ripe fruits) |
| 15-17 | Young tree (woody trunk, branches, round canopy) |
| 18-20 | Established (taller, denser canopy) |
| 21-23 | Flourishing (abundant, fuller, more fruit) |
| 24-26 | Ancient (largest single tree, gnarled trunk) |
| 27 | Grove-hint (widest, oldest form) |

Each frame's per-frame delta (the small step toward its target) is defined in
`FRAME_DELTAS` in `scripts/generate_garden_tree.py`. Every edit instruction is wrapped with
`EDIT_PREFIX`/`EDIT_SUFFIX`, which repeat "keep the pot, camera, lighting and seamless pale
cream background identical; change only the plant."

## Running / regenerating

The WaveSpeed API key is read from `WAVESPEED_API_KEY` and is never stored in the repo.
Export it inline for a single command only (prefix with `rtk` per project convention):

```bash
# Full chain 00→27 (each frame depends on the previous; skips frames that already exist):
WAVESPEED_API_KEY=wsk_live_... python3 scripts/generate_garden_tree.py

# One frame (frame N-1 must already exist — its source URL is read from chain_state.json):
WAVESPEED_API_KEY=wsk_live_... python3 scripts/generate_garden_tree.py --only 5

# Force a redo of a frame:
WAVESPEED_API_KEY=wsk_live_... python3 scripts/generate_garden_tree.py --only 5 --force
```

Flags: `--only N`, `--force`, `--model`, `--edit-model`, `--no-rmbg`, `--size` (frame 00,
default `768*1024`), `--aspect` (edit frames, default `3:4`), `--guidance` (edit strength;
**lower = gentler / closer to the previous frame**, default `3.0`), `--seed` (frame 00,
default `1234`). Idempotent — skips a frame whose PNG already exists (with a cached chain
URL) unless `--force`.

## Known issues / tuning

- **Chain drift (resolved by switching to nano-banana).** The original `flux-kontext-pro`
  chain held for frames 00-14 but from ~frame 15 degraded into a stylized **topiary /
  "pom-pom" look** (fuzzy spherical canopy, cartoonish fruit) — cumulative edit artifacts,
  worsened by "round canopy" wording nudging it toward literal spheres. Switching the
  default to **`google/nano-banana/edit`** fixed this: in a 5-frame seed→sprouting sample
  the pot, soil, lighting and camera stayed essentially identical with no drift. If a long
  chain ever starts drifting again, options: lower the per-frame delta, drop "round canopy"
  phrasing in `FRAME_DELTAS`, or re-anchor (short 2-3 edit chains per stage). The script
  also supports an `ANCHOR_URL` reference image to pin the pot/scene across the chain.
- **Early frames change subtly.** In the seed→sprouting range nano-banana makes very small
  edits (the sprout stays tiny across 00-02). If you want more visible frame-to-frame
  change early, make the first few `FRAME_DELTAS` more pronounced.
- **Asset weight.** nano-banana frames are high-detail (~1.9MB each → ~53MB for 28). Plan
  to downscale/compress before bundling into the app.
- **Dimensions.** nano-banana frames come back a consistent 864×1184 (3:4). (A flux-dev
  base frame would be 768×1024.) The Flutter side should `BoxFit.contain` regardless.
- **Transparency confirmed.** All saved frames are true RGBA (alpha channel) PNGs.
- **Single-frame regen depends on a live source URL.** WaveSpeed output URLs in
  `chain_state.json` are CDN links that eventually expire; if `--only N` later fails to
  fetch frame N-1's source, re-run the chain from an earlier intact frame with `--force`.
