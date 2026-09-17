#!/usr/bin/env python3
"""
scripts/composite_chatgpt_vending_atlas.py
Bakes godot/textures/urban_clutter/tex_vending_machine.png (2048x2048)
using ChatGPT-generated transparent PNG assets.
Fits UV coordinates in scripts/blender_build_vending_machine.py perfectly.
"""

from PIL import Image, ImageOps
import os

OUT_DIR = "godot/textures/urban_clutter"
REF_DIR = "docs/visual_direction/references"
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(REF_DIR, exist_ok=True)

def bake_from_single_elevation(front_image_path):
    """
    Slices an orthographic front elevation from ChatGPT
    and maps it into the 2048x2048 UV layout for prop_vending_machine.glb.
    """
    raw = Image.open(front_image_path).convert("RGBA")
    bbox = raw.getbbox()
    if bbox:
        raw = raw.crop(bbox)
    W, H = raw.size

    atlas = Image.new("RGBA", (2048, 2048), (38, 44, 50, 255))

    # 1. Goods Display Window: Zone (0, 0, 1024, 1024) [uv: 0.0, 0.5 -> 0.5, 1.0]
    # Crop the display window (left ~63% width, 16% to 68% height)
    window_crop = raw.crop((0, int(H * 0.16), int(W * 0.63), int(H * 0.68))).resize((1024, 1024), Image.Resampling.LANCZOS)
    atlas.paste(window_crop, (0, 0))

    # 2. Base Casing fill: Zone (0, 1024, 1024, 2048) [uv: 0.0, 0.0 -> 0.5, 0.5]
    # Use dark graphite steel texture from side body of raw sprite
    casing = raw.crop((int(W * 0.02), int(H * 0.16), int(W * 0.30), int(H * 0.68))).resize((1024, 1024), Image.Resampling.LANCZOS)
    atlas.paste(casing, (0, 1024))

    # 3. Marquee Header Sign: Zone (1024, 0, 2048, 512) [uv: 0.5, 0.75 -> 1.0, 1.0]
    # Crop top marquee sign (full width, 0% to 16% height)
    marquee_crop = raw.crop((0, 0, W, int(H * 0.16))).resize((1024, 512), Image.Resampling.LANCZOS)
    atlas.paste(marquee_crop, (1024, 0))

    # 4. Control Interface / Keypad & Terminal: Zone (1024, 512, 1536, 2048) [uv: 0.5, 0.0 -> 0.75, 0.75]
    # Crop right-hand control interface (right ~37% width, 16% to 68% height)
    keypad_crop = raw.crop((int(W * 0.63), int(H * 0.16), W, int(H * 0.68))).resize((512, 1536), Image.Resampling.LANCZOS)
    atlas.paste(keypad_crop, (1024, 512))

    # 5. Bottom Dispenser Hopper: Zone (1536, 512, 2048, 1536) [uv: 0.75, 0.25 -> 1.0, 0.75]
    # Crop the bottom door flap (68% to 92% height)
    hopper_crop = raw.crop((int(W * 0.05), int(H * 0.68), int(W * 0.95), int(H * 0.92))).resize((512, 1024), Image.Resampling.LANCZOS)
    atlas.paste(hopper_crop, (1536, 512))

    # 6. Base Feet & Louvers: Zone (1536, 0, 2048, 512) [uv: 0.75, 0.75 -> 1.0, 1.0]
    # Crop base skid feet (92% to 100% height)
    feet_crop = raw.crop((int(W * 0.05), int(H * 0.92), int(W * 0.95), H)).resize((512, 512), Image.Resampling.LANCZOS)
    atlas.paste(feet_crop, (1536, 0))

    out_path = f"{OUT_DIR}/tex_vending_machine.png"
    atlas.save(out_path)
    print(f"[ATLAS_BAKER] Successfully baked ChatGPT texture into: {out_path} ({atlas.size})")

def bake_from_modular_components(marquee_path, window_path, keypad_path, hopper_path):
    """
    Composites separate high-res ChatGPT components into the 2048x2048 texture atlas.
    """
    atlas = Image.new("RGBA", (2048, 2048), (38, 44, 50, 255))

    if os.path.exists(marquee_path):
        m_img = Image.open(marquee_path).convert("RGBA").resize((1024, 512), Image.Resampling.LANCZOS)
        atlas.paste(m_img, (1024, 1536), m_img)

    if os.path.exists(window_path):
        w_img = Image.open(window_path).convert("RGBA").resize((1024, 1024), Image.Resampling.LANCZOS)
        atlas.paste(w_img, (0, 1024), w_img)

    if os.path.exists(keypad_path):
        k_img = Image.open(keypad_path).convert("RGBA").resize((512, 1536), Image.Resampling.LANCZOS)
        atlas.paste(k_img, (1024, 0), k_img)

    if os.path.exists(hopper_path):
        h_img = Image.open(hopper_path).convert("RGBA").resize((512, 1024), Image.Resampling.LANCZOS)
        atlas.paste(h_img, (1536, 512), h_img)

    out_path = f"{OUT_DIR}/tex_vending_machine.png"
    atlas.save(out_path)
    print(f"[ATLAS_BAKER] Successfully baked modular components into: {out_path}")

if __name__ == "__main__":
    import sys
    single_ref = f"{REF_DIR}/chatgpt_gen_vending_machine.png"
    if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
        bake_from_single_elevation(sys.argv[1])
    elif os.path.exists(single_ref):
        bake_from_single_elevation(single_ref)
    else:
        print(f"[ATLAS_BAKER] Save ChatGPT generation to {single_ref} and rerun this script.")
