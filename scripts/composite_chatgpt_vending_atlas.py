#!/usr/bin/env python3
"""
scripts/composite_chatgpt_vending_atlas.py
Bakes godot/textures/urban_clutter/tex_vending_machine.png (2048x2048)
using ChatGPT-generated transparent PNG assets.
Fits UV coordinates in scripts/blender_build_vending_machine.py with zero overlap.
"""

from PIL import Image, ImageOps
import os

OUT_DIR = "godot/textures/urban_clutter"
REF_DIR = "docs/visual_direction/references"
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(REF_DIR, exist_ok=True)

def bake_from_single_elevation(front_image_path):
    """
    Slices the orthographic front elevation from ChatGPT
    and maps it into the 2048x2048 UV layout for prop_vending_machine.glb.
    """
    raw = Image.open(front_image_path).convert("RGBA")
    bbox = raw.getbbox()
    if bbox:
        raw = raw.crop(bbox)
    W, H = raw.size

    atlas = Image.new("RGBA", (2048, 2048), (35, 38, 42, 255))

    # 1. Goods Display Window: Zone (0, 0, 1024, 1024) [uv: 0.0, 0.5 -> 0.5, 1.0]
    # Slices the illuminated display window (cans, stims, crates)
    window_crop = raw.crop((85, 270, 570, 1215)).resize((1024, 1024), Image.Resampling.LANCZOS)
    atlas.paste(window_crop, (0, 0))

    # 2. Base Casing fill: Zone (0, 1024, 1024, 2048) [uv: 0.0, 0.0 -> 0.5, 0.5]
    # Seamless dark weathered industrial steel texture from outer frame pillar
    pillar = raw.crop((32, 400, 80, 1100)).resize((1024, 1024), Image.Resampling.LANCZOS)
    atlas.paste(pillar, (0, 1024))

    # 3. Marquee Header Sign: Zone (1024, 0, 2048, 512) [uv: 0.5, 0.75 -> 1.0, 1.0]
    # Full-width curved backlit sign with NEO-COLA typography & neon glow
    marquee_crop = raw.crop((25, 20, W - 25, 275)).resize((1024, 512), Image.Resampling.LANCZOS)
    atlas.paste(marquee_crop, (1024, 0))

    # 4. Control Interface / Keypad & Terminal: Zone (1024, 512, 1536, 2048) [uv: 0.5, 0.0 -> 0.75, 0.75]
    # CRT monitor (0.840 MHz), numeric keypad, card slot, bypass wiring
    keypad_crop = raw.crop((570, 270, 875, 1215)).resize((512, 1536), Image.Resampling.LANCZOS)
    atlas.paste(keypad_crop, (1024, 512))

    # 5. Bottom Dispenser Hopper: Zone (1536, 512, 2048, 1536) [uv: 0.75, 0.25 -> 1.0, 0.75]
    # Heavy steel door flap with hazard yellow/black stripes & PUSH stencil
    hopper_crop = raw.crop((170, 1235, 745, 1535)).resize((512, 1024), Image.Resampling.LANCZOS)
    atlas.paste(hopper_crop, (1536, 512))

    # 6. Base Feet, Louvers & Conduit: Zone (1536, 1536, 2048, 2048) [uv: 0.75, 0.0 -> 1.0, 0.25]
    # Base skid feet, cooling vents, and rear box
    feet_crop = raw.crop((25, 1530, W - 25, H)).resize((512, 512), Image.Resampling.LANCZOS)
    atlas.paste(feet_crop, (1536, 1536))

    out_path = f"{OUT_DIR}/tex_vending_machine.png"
    atlas.save(out_path)
    print(f"[ATLAS_BAKER] Successfully baked ChatGPT texture into: {out_path} ({atlas.size})")

if __name__ == "__main__":
    import sys
    single_ref = f"{REF_DIR}/chatgpt_gen_vending_machine.png"
    if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
        bake_from_single_elevation(sys.argv[1])
    elif os.path.exists(single_ref):
        bake_from_single_elevation(single_ref)
    else:
        print(f"[ATLAS_BAKER] Save ChatGPT generation to {single_ref} and rerun this script.")
