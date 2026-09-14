#!/usr/bin/env python3
"""
Post-processes raw DALL-E / ChatGPT generated textures:
- Crops to 1:1 square
- Resizes to 512x512 using high-quality Lanczos resampling
- Applies seamless border wrapping/blending for tileable materials
- Exports production PNG to godot/textures/urban_clutter/
"""

import os
import sys
import numpy as np
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../../.."))
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "godot/textures/urban_clutter")

def make_seamless(im: Image.Image, blend_width: int = 32) -> Image.Image:
    """Soft linear crossfade blending along edges to guarantee seamless tiling."""
    arr = np.array(im, dtype=np.float32)
    h, w, c = arr.shape
    bw = min(blend_width, w // 4, h // 4)
    
    # Blend horizontal edges (left and right)
    for x in range(bw):
        alpha = (x / float(bw))
        left = arr[:, x, :].copy()
        right = arr[:, w - 1 - (bw - 1 - x), :].copy()
        # Smooth blend
        t = 0.5 * (1.0 - np.cos(alpha * np.pi))
        arr[:, x, :] = (1.0 - t) * right + t * left
        arr[:, w - bw + x, :] = (1.0 - (1.0 - t)) * left + (1.0 - t) * right

    # Blend vertical edges (top and bottom)
    for y in range(bw):
        alpha = (y / float(bw))
        top = arr[y, :, :].copy()
        bottom = arr[h - 1 - (bw - 1 - y), :, :].copy()
        t = 0.5 * (1.0 - np.cos(alpha * np.pi))
        arr[y, :, :] = (1.0 - t) * bottom + t * top
        arr[h - bw + y, :, :] = (1.0 - (1.0 - t)) * top + (1.0 - t) * bottom

    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))

def process_image(src_path: str, dst_filename: str, seamless: bool = False, target_size: int = 512):
    if not os.path.exists(src_path):
        print(f"Error: Source image not found: {src_path}", file=sys.stderr)
        return False
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    dst_path = os.path.join(OUTPUT_DIR, dst_filename)

    im = Image.open(src_path).convert("RGB")
    w, h = im.size
    min_dim = min(w, h)
    
    # Center crop to square
    left = (w - min_dim) // 2
    top = (h - min_dim) // 2
    im_sq = im.crop((left, top, left + min_dim, top + min_dim))
    
    # High-quality resize
    im_resized = im_sq.resize((target_size, target_size), Image.Resampling.LANCZOS)
    
    if seamless:
        im_final = make_seamless(im_resized, blend_width=32)
    else:
        im_final = im_resized
        
    im_final.save(dst_path, "PNG", optimize=True)
    print(f"Saved: {dst_path} ({target_size}x{target_size}, seamless={seamless})")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: process_ai_textures.py <src_image> <dst_name.png> [--seamless]")
        sys.exit(1)
    
    src = sys.argv[1]
    dst = sys.argv[2]
    is_seamless = "--seamless" in sys.argv
    success = process_image(src, dst, seamless=is_seamless)
    sys.exit(0 if success else 1)
