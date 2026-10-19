#!/usr/bin/env python3
"""Generate the 28-frame "growing tree in a terracotta pot" flipbook for Garden of Grace.

This uses a CHAINED image-to-image pipeline (the "AI flipbook" approach) so the pot,
soil, camera, lighting and background stay consistent across all 28 frames — independent
text2img would flicker.

Pipeline:
    Frame 00 : TEXT-TO-IMAGE (flux-dev, fixed seed, cream seamless background) — the
               seed/sprout starting point. We keep TWO versions: the raw cream-background
               image (the "chain source", reused as input for frame 01) and a
               background-removed transparent PNG (the saved asset tree_00.png).
    Frame NN : IMAGE-TO-IMAGE EDIT (default wavespeed-ai/flux-kontext-pro), feeding the
               PREVIOUS frame's cream-background image as input with a small "grow a
               little more" instruction. Then background-remove → tree_NN.png, and keep
               the new cream-bg image as the chain source for the next frame.

Chain sources are remembered as URLs in assets/garden/tree/_chain/chain_state.json (and a
local cream-bg copy is saved to _chain/tree_NN_src.png for backup/debugging). Running a
single frame N>0 with --only requires frame N-1 to have been produced already (its URL is
read from chain_state.json).

The WaveSpeed API key is read from WAVESPEED_API_KEY and is NEVER stored in this file:

    WAVESPEED_API_KEY=wsk_live_... python3 scripts/generate_garden_tree.py --only 0

Stdlib only (urllib + json).
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

API_BASE = "https://api.wavespeed.ai/api/v3"

DEFAULT_GEN_MODEL = "google/nano-banana/text-to-image"  # text2img for frame 00
DEFAULT_EDIT_MODEL = "google/nano-banana/edit"          # image2image edit for 01..27
RMBG_MODEL = "wavespeed-ai/image-background-remover"     # transparent cutout

OUTPUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "assets",
    "garden",
    "tree",
)
CHAIN_DIR = os.path.join(OUTPUT_DIR, "_chain")
CHAIN_STATE = os.path.join(CHAIN_DIR, "chain_state.json")

FRAME_COUNT = 28

# Set after frame 00 (or loaded from chain state): the canonical pot reference image, fed
# as a SECOND reference to every nano-banana edit so the pot/scene can't drift away over a
# long chain (the cause of the earlier "plastic topiary" degradation).
ANCHOR_URL = None

# Frame 00 text-to-image prompt (cream seamless background, opaque).
SEED_SUBJECT = (
    "bare dark moist soil in a rustic terracotta plant pot with a single sprouting seed, "
    "a tiny green tip just breaking the surface"
)
GEN_STYLE_SUFFIX = (
    " - studio product photograph, the pot centered with its base at the bottom of the "
    "frame, slight high angle straight-on, soft warm diffused daylight, seamless pale "
    "cream studio background, ultra-detailed realistic soil and bark, shallow depth of "
    "field, 3:4 portrait, photorealistic, no text, no watermark."
)

# Edit instruction wrapper for frames 01..27. The per-frame delta is inserted in the
# middle; the wrapper hammers on keeping the scene identical so only the plant grows.
EDIT_PREFIX = (
    "The exact same small potted tree in the exact same rustic terracotta pot with dark "
    "soil. Keep the pot, the camera angle, the soft warm lighting and the seamless pale "
    "cream studio background completely identical. Change only the plant by growing it a "
    "little more: "
)
EDIT_SUFFIX = (
    ". Centered, base of the pot at the bottom of the frame, ultra-detailed realistic "
    "bark and leaves, photorealistic, 3:4 portrait, no text, no watermark."
)

# Per-frame growth deltas (frame 00 uses SEED_SUBJECT instead). 28 frames mapped across
# the spec's 10 named life-stages, ~3 frames each, so the tree grows continuously.
FRAME_DELTAS = {
    # 00-02 Seed
    1: "the green tip is slightly taller, a thin pale-green shoot a bit more emerged from the soil",
    2: "the shoot is a little taller with the very first pair of tiny leaf buds forming at the top",
    # 03-05 Sprouting
    3: "two small cotyledon leaves are now open at the top of the short shoot",
    4: "the stem is slightly taller, the cotyledons fuller, and a third small leaf is starting",
    5: "a short stem with a few small true leaves, slightly bushier",
    # 06-08 Growing
    6: "more leaves, the stem a bit thicker and taller, looking bushier",
    7: "noticeably bushier with many small leaves and a thin woody base starting to form",
    8: "a small leafy plant with fuller foliage, the base of the stem turning slightly woody",
    # 09-11 Blossoming
    9: "a little larger, with the first few small blossom buds appearing among the leaves",
    10: "several delicate white-and-pink blossoms now open among the green leaves",
    11: "more blossoms across a fuller canopy of leaves",
    # 12-14 Bearing fruit
    12: "the blossoms are fading as the first tiny green fruits begin to form",
    13: "several small fruits are growing larger and starting to ripen toward red",
    14: "the first few ripe red fruits appear among the foliage",
    # 15-17 Young tree
    15: "now a clear slender woody trunk with a few branches and a rounder green canopy, a few red fruits",
    16: "the trunk a bit thicker, more branches, a denser round canopy",
    17: "a healthy young tree with a fuller round green canopy and scattered red fruits",
    # 18-20 Established
    18: "taller, with a thicker trunk and a denser, broader canopy",
    19: "the canopy fuller and wider, with more red fruits throughout",
    20: "an established tree, tall with a dense lush canopy and abundant fruit",
    # 21-23 Flourishing
    21: "even fuller and more abundant, a thicker trunk and very dense foliage heavy with fruit",
    22: "lush and flourishing, a broad canopy overflowing with ripe red fruit",
    23: "at peak abundance, a very full broad canopy laden with fruit",
    # 24-26 Ancient
    24: "now older, with a thicker gnarled trunk and a large spreading canopy",
    25: "an ancient tree, thick gnarled trunk and a very large wide canopy",
    26: "the largest single tree, a massive gnarled trunk and a huge spreading canopy",
    # 27 Grove-hint
    27: "its widest, oldest form, an enormous spreading canopy hinting at a small grove, still in the same terracotta pot",
}

# Progressive wilt edits (health levels 1..4), chained from the healthy (h0) frame so the
# wilt deepens smoothly. Level 0 = healthy (the growth frame itself). Spec §8: wilt is
# "resting", never death — the plant stays alive in the same pot.
WILT_PREFIX = (
    "The exact same potted tree in the exact same rustic terracotta pot with dark soil. "
    "Keep the pot, the camera angle, the soft warm lighting and the seamless pale cream "
    "studio background completely identical, and keep the plant the same overall size and "
    "shape. Only change the health of the foliage: "
)
WILT_SUFFIX = (
    ". Centered, base of the pot at the bottom of the frame, photorealistic, 3:4 portrait, "
    "no text, no watermark."
)
WILT_DELTAS = {
    1: "the leaves are very slightly drooping and a touch less vivid green, the earliest hint of thirst",
    2: "the leaves are clearly drooping and softening, with some edges turning pale yellow",
    3: "many leaves are wilted and yellow-brown, drooping heavily, and a few have fallen onto the soil",
    4: "severely wilted and dry: most leaves brown, shriveled or fallen and branches bare and drooping, but the plant is still alive in the same pot",
}

POLL_INTERVAL_S = 2
POLL_TIMEOUT_S = 600  # nano-banana Pro edits can take 150s+ under load; give ample margin


def log(msg):
    print(msg, flush=True)


def die(msg, code=1):
    print("ERROR: " + msg, file=sys.stderr, flush=True)
    sys.exit(code)


def get_api_key():
    key = os.environ.get("WAVESPEED_API_KEY")
    if not key:
        die(
            "WAVESPEED_API_KEY environment variable is not set. Export it inline for a "
            "single command, e.g.:\n"
            "  WAVESPEED_API_KEY=wsk_live_... python3 scripts/generate_garden_tree.py --only 0"
        )
    return key


def asset_path(i):
    return os.path.join(OUTPUT_DIR, "tree_{:02d}.png".format(i))


def src_path(i):
    return os.path.join(CHAIN_DIR, "tree_{:02d}_src.png".format(i))


def load_state():
    if os.path.exists(CHAIN_STATE):
        try:
            with open(CHAIN_STATE) as f:
                return json.load(f)
        except (ValueError, OSError):
            return {}
    return {}


def save_state(state):
    os.makedirs(CHAIN_DIR, exist_ok=True)
    with open(CHAIN_STATE, "w") as f:
        json.dump(state, f, indent=2)


def _request(url, api_key, method="GET", body=None):
    data = None
    headers = {"Authorization": "Bearer " + api_key}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        detail = ""
        try:
            detail = e.read().decode("utf-8")
        except Exception:
            pass
        die("HTTP {} from {}: {}".format(e.code, url, detail))
    except urllib.error.URLError as e:
        die("Network error contacting {}: {}".format(url, e))


def submit(model, payload, api_key):
    url = "{}/{}".format(API_BASE, model)
    resp = _request(url, api_key, method="POST", body=payload)
    data = resp.get("data") or {}
    req_id = data.get("id")
    poll_url = (data.get("urls") or {}).get("get")
    if not req_id:
        die("No request id in submit response: {}".format(json.dumps(resp)[:500]))
    if not poll_url:
        poll_url = "{}/predictions/{}/result".format(API_BASE, req_id)
    return req_id, poll_url


def poll(poll_url, api_key, label):
    started = time.time()
    while True:
        elapsed = time.time() - started
        if elapsed > POLL_TIMEOUT_S:
            die("Timed out after {}s waiting for {}".format(POLL_TIMEOUT_S, label))
        resp = _request(poll_url, api_key)
        data = resp.get("data") or {}
        status = data.get("status")
        if status == "completed":
            outputs = data.get("outputs") or []
            if not outputs:
                die("{} completed but returned no outputs".format(label))
            log("    {} completed in {:.0f}s".format(label, elapsed))
            return outputs[0]
        if status == "failed":
            die("{} failed: {}".format(label, data.get("error") or json.dumps(resp)[:500]))
        log("    {} status={} ({:.0f}s)".format(label, status or "?", elapsed))
        time.sleep(POLL_INTERVAL_S)


def download(url, dest):
    try:
        with urllib.request.urlopen(urllib.request.Request(url), timeout=120) as resp:
            content = resp.read()
    except (urllib.error.HTTPError, urllib.error.URLError) as e:
        die("Failed to download {}: {}".format(url, e))
    if not content:
        die("Downloaded empty file from {}".format(url))
    with open(dest, "wb") as f:
        f.write(content)
    return len(content)


def gen_frame0(args, api_key):
    """Text-to-image for frame 00; returns the cream-background image URL."""
    prompt = SEED_SUBJECT + GEN_STYLE_SUFFIX
    if "nano-banana" in args.model:
        # Gemini 2.5 Flash Image text-to-image: aspect_ratio, no size/seed.
        payload = {
            "prompt": prompt,
            "aspect_ratio": args.aspect,
            "output_format": "png",
            "enable_base64_output": False,
        }
        log("  -> text2img frame 00 via {} (aspect {})".format(args.model, args.aspect))
    else:
        # Flux-style: explicit size + seed.
        payload = {
            "prompt": prompt,
            "size": args.size,
            "num_images": 1,
            "seed": args.seed,
            "output_format": "png",
            "enable_base64": False,
        }
        log("  -> text2img frame 00 via {} (seed {})".format(args.model, args.seed))
    _id, poll_url = submit(args.model, payload, api_key)
    return poll(poll_url, api_key, "gen[00]")


def build_edit_payload(model, image_url, prompt, args, anchor_url=None):
    if "nano-banana" in model:
        # nano-banana edit takes an array of reference image URLs. Passing the canonical pot
        # reference (frame 00) as a 2nd image re-grounds every frame on the real pot and
        # fights cumulative chain drift.
        images = [image_url]
        if anchor_url and anchor_url != image_url:
            images.append(anchor_url)
        return {
            "prompt": prompt,
            "images": images,
            "aspect_ratio": args.aspect,
            "output_format": "png",
            "enable_base64_output": False,
        }
    # Flux Kontext family: single image URL + guidance_scale.
    return {
        "prompt": prompt,
        "image": image_url,
        "aspect_ratio": args.aspect,
        "guidance_scale": args.guidance,
        "output_format": "png",
        "enable_base64": False,
    }


def stage_constraint(i):
    """Phase guard aligned to the model's behaviour (it insists mature pomegranates bear
    fruit). Keep the early stages strictly foliage-only; let flowers then fruit arrive
    naturally on the mature tree from ~frame 25 — WITHOUT force-removing (which caused
    size jumps). Vegetative-dominant: fruit only in the last ~40%."""
    if i <= 24:
        return (" IMPORTANT: NO flowers and NO fruit at all — only green and coppery foliage "
                "and twigs. If the previous image shows any flowers or fruit, remove them.")
    if i <= 30:
        return (" Keep the tree the SAME size and shape as the previous image; a few vermilion "
                "urn-shaped flower buds may appear, and the first small fruit may just begin "
                "to form naturally.")
    # Ripe / mature phase: the AI flipbook tends to SHRINK the tree and lose the
    # trunk here (frames 43-46 regressed into a small shrub). Hard-lock size
    # monotonicity and the established trunk so the finale only matures.
    return (" CRITICAL: the tree must be the SAME overall size or slightly LARGER than "
            "the previous image — never smaller, never younger, never a small potted "
            "shrub. Keep the established woody/gnarled trunk and the broad mature canopy "
            "from the previous image; the trunk only thickens. Change mainly the fruit "
            "(it ripens) plus a little extra canopy fullness. Do NOT reset to a seedling.")


def edit_frame(i, prev_url, args, api_key):
    """Image-to-image edit for frame i (>0); returns the new cream-background URL."""
    prompt = EDIT_PREFIX + FRAME_DELTAS[i] + stage_constraint(i) + EDIT_SUFFIX
    payload = build_edit_payload(args.edit_model, prev_url, prompt, args, ANCHOR_URL)
    log("  -> edit frame {:02d} via {} (guidance {})".format(i, args.edit_model, args.guidance))
    _id, poll_url = submit(args.edit_model, payload, api_key)
    return poll(poll_url, api_key, "edit[{:02d}]".format(i))


def remove_bg(image_url, i, api_key):
    log("  -> background removal via {}".format(RMBG_MODEL))
    _id, poll_url = submit(RMBG_MODEL, {"image": image_url}, api_key)
    return poll(poll_url, api_key, "rmbg[{:02d}]".format(i))


def wilt_asset_path(g, h):
    return os.path.join(OUTPUT_DIR, "tree_{:02d}_h{:d}.png".format(g, h))


def gen_wilt(g, args, api_key, state):
    """Generate wilt levels h1..h4 for growth frame g, chained from its healthy (h0) frame
    so the wilt deepens smoothly. Anchored to the h0 image so the tree/pot stay identical.
    Idempotent: skips levels whose PNG already exists (resumable across credit top-ups)."""
    h0_url = state.get(str(g))
    if not h0_url:
        log("[wilt g{:02d}] no healthy source yet, skipping".format(g))
        return
    prev = h0_url
    for h in (1, 2, 3, 4):
        dest = wilt_asset_path(g, h)
        skey = "w{}_{}".format(g, h)
        if os.path.exists(dest) and not args.force:
            cached = state.get(skey)
            if cached:
                prev = cached
                continue
        prompt = WILT_PREFIX + WILT_DELTAS[h] + WILT_SUFFIX
        payload = build_edit_payload(args.edit_model, prev, prompt, args, h0_url)
        log("  -> wilt g{:02d} h{} via {}".format(g, h, args.edit_model))
        _id, poll_url = submit(args.edit_model, payload, api_key)
        cream = poll(poll_url, api_key, "wilt[g{:02d}h{}]".format(g, h))
        state[skey] = cream
        save_state(state)
        prev = cream
        final_url = cream if args.no_rmbg else remove_bg(cream, g, api_key)
        size = download(final_url, dest)
        log("  saved {} ({} bytes)".format(dest, size))


def ensure_frame(i, prev_url, state, args, api_key):
    """Produce frame i if needed. Returns (cream_url, asset_size)."""
    global ANCHOR_URL
    a_path = asset_path(i)

    if os.path.exists(a_path) and not args.force:
        cached_url = state.get(str(i))
        if cached_url is not None:
            log("[{:02d}] tree_{:02d}.png exists, skipping (chain url cached)".format(i, i))
            return cached_url, os.path.getsize(a_path)
        log("[{:02d}] tree_{:02d}.png exists but no cached chain url; regenerating "
            "to keep the chain intact".format(i, i))

    log("[{:02d}] Generating tree_{:02d}.png ...".format(i, i))

    if i == 0:
        cream_url = gen_frame0(args, api_key)
        ANCHOR_URL = cream_url
    else:
        if not prev_url:
            die("Frame {:02d} needs the previous frame's chain source, but none is "
                "available. Run frame {:02d} first (chained pipeline).".format(i, i - 1))
        cream_url = edit_frame(i, prev_url, args, api_key)

    # Persist the cream-bg chain source (URL in state + local backup copy).
    os.makedirs(CHAIN_DIR, exist_ok=True)
    download(cream_url, src_path(i))
    state[str(i)] = cream_url
    save_state(state)

    # Background-remove → transparent asset (unless disabled).
    final_url = cream_url if args.no_rmbg else remove_bg(cream_url, i, api_key)
    size = download(final_url, a_path)
    log("  saved {} ({} bytes)".format(a_path, size))
    return cream_url, size


def main():
    parser = argparse.ArgumentParser(description="Generate the Garden of Grace 28-frame tree flipbook.")
    parser.add_argument("--only", type=int, default=None, metavar="N",
                        help="Generate just frame N (0-27). Needs frame N-1 already done.")
    parser.add_argument("--force", action="store_true",
                        help="Regenerate even if the frame PNG already exists.")
    parser.add_argument("--model", default=DEFAULT_GEN_MODEL,
                        help="Text2img model for frame 00 (default: %(default)s).")
    parser.add_argument("--edit-model", default=DEFAULT_EDIT_MODEL,
                        help="Image2image edit model for the chain (default: %(default)s).")
    parser.add_argument("--prompts", default=None,
                        help="JSON prompts file (base_prompt/style_suffix/edit_prefix/"
                             "edit_suffix/growth_deltas/wilt_*); overrides built-ins and "
                             "sets frame count from growth_deltas.")
    parser.add_argument("--grid", action="store_true",
                        help="After the growth frames, also generate wilt levels h1..h4 for "
                             "each growth frame (the 2D health grid).")
    parser.add_argument("--no-rmbg", action="store_true",
                        help="Skip background removal (opaque cream-background output).")
    parser.add_argument("--size", default="768*1024",
                        help="Frame 00 size as WIDTH*HEIGHT (default: %(default)s).")
    parser.add_argument("--aspect", default="3:4",
                        help="Edit-model aspect ratio (default: %(default)s).")
    parser.add_argument("--guidance", type=float, default=3.0,
                        help="Edit guidance_scale; lower = gentler, closer to previous "
                             "frame (default: %(default)s).")
    parser.add_argument("--seed", type=int, default=1234,
                        help="Seed for frame 00 (default: %(default)s).")
    args = parser.parse_args()

    global SEED_SUBJECT, GEN_STYLE_SUFFIX, EDIT_PREFIX, EDIT_SUFFIX, FRAME_DELTAS
    global WILT_PREFIX, WILT_SUFFIX, WILT_DELTAS, FRAME_COUNT, ANCHOR_URL

    if args.prompts:
        with open(args.prompts) as f:
            p = json.load(f)
        SEED_SUBJECT = p["base_prompt"]
        GEN_STYLE_SUFFIX = p["style_suffix"]
        EDIT_PREFIX = p["edit_prefix"]
        EDIT_SUFFIX = p["edit_suffix"]
        FRAME_DELTAS = {int(k): v for k, v in p["growth_deltas"].items()}
        if p.get("wilt_prefix"):
            WILT_PREFIX = p["wilt_prefix"]
        if p.get("wilt_suffix"):
            WILT_SUFFIX = p["wilt_suffix"]
        if p.get("wilt_deltas"):
            WILT_DELTAS = {int(k): v for k, v in p["wilt_deltas"].items()}
        FRAME_COUNT = len(FRAME_DELTAS) + 1
        log("Loaded prompts from {} ({} growth frames)".format(args.prompts, FRAME_COUNT))

    if args.only is not None and not (0 <= args.only < FRAME_COUNT):
        die("--only must be between 0 and {}".format(FRAME_COUNT - 1))

    api_key = get_api_key()
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(CHAIN_DIR, exist_ok=True)
    state = load_state()
    ANCHOR_URL = state.get("0")  # canonical pot anchor (frame 00), if already generated

    log("Output dir: {}".format(OUTPUT_DIR))
    log("gen={} | edit={} | rmbg={} | frames={} | grid={}".format(
        args.model, args.edit_model,
        "disabled" if args.no_rmbg else RMBG_MODEL, FRAME_COUNT, bool(args.grid)))

    # ---- Growth (healthy h0) ----
    indices = [args.only] if args.only is not None else list(range(FRAME_COUNT))
    prev_url = None
    if indices[0] > 0:
        prev_url = state.get(str(indices[0] - 1))
    for i in indices:
        prev_url, size = ensure_frame(i, prev_url, state, args, api_key)

    # ---- Wilt grid (h1..h4 per growth frame) ----
    if args.grid and args.only is None:
        log("\n-- Wilt grid --")
        for g in range(FRAME_COUNT):
            gen_wilt(g, args, api_key, state)

    log("\nDone.")


if __name__ == "__main__":
    main()
