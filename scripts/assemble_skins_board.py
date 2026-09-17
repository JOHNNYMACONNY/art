#!/usr/bin/env python3
"""
scripts/assemble_skins_board.py
Assembles a high-resolution presentation board showing:
1. ChatGPT Concept Reference Sheet for "Silent Core Infiltrator"
2. In-engine 3D real-time Godot renders comparing Base Skin vs Silent Core Skin
"""

import os
from PIL import Image, ImageDraw, ImageFont

def get_font(size, bold=True):
    font_paths = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Supplemental/Impact.ttf",
        "/System/Library/Fonts/SFNSMono.ttf",
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                pass
    return ImageFont.load_default()

def main():
    chatgpt_sheet_path = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/chatgpt_alt_skin_silent_core.png"
    render_front_path = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/skins_comparison_front_32deg.png"
    render_rear_path = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/skins_comparison_rear_32deg.png"
    render_top_path = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/skins_comparison_topdown.png"

    out_board_path = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/board_alt_skin_silent_core.png"
    artifact_board_path = "/Users/bobbyinthelobby/.gemini/antigravity/brain/beee1f70-b0b4-4831-a112-9a9b7c603049/board_alt_skin_silent_core.png"

    # Board layout:
    # Width: 2560, Height: 2160
    # Top Section: ChatGPT Concept Model Sheet (Width: 2480, Height: 1395)
    # Bottom Section: 3 in-engine real-time renders (Front 32°, Rear 32°, Top-Down)

    W, H = 2560, 2200
    board = Image.new("RGBA", (W, H), (14, 15, 18, 255))
    draw = ImageDraw.Draw(board)

    font_title = get_font(44, bold=True)
    font_sub = get_font(26, bold=False)
    font_label = get_font(30, bold=True)
    font_tag = get_font(20, bold=True)

    # Header
    draw.rectangle([0, 0, W, 90], fill=(22, 24, 30, 255))
    draw.text((40, 22), "RUNNER PROTAGONIST // ALTERNATE SKIN: SILENT CORE INFILTRATOR (ARCHIVE GHOST)", fill=(245, 248, 255, 255), font=font_title)
    draw.text((W - 600, 32), "CHINATOWN WARS PRODUCTION PIPELINE", fill=(255, 85, 0, 255), font=font_tag)

    # Section 1: ChatGPT Concept Sheet
    draw.rectangle([40, 110, W - 40, 150], fill=(30, 33, 40, 255))
    draw.text((50, 118), "1. CHATGPT PRODUCTION REFERENCE SHEET (FACTION LORE + MODEL SHEET + UV ATLAS SPEC)", fill=(0, 229, 255, 255), font=font_label)

    if os.path.exists(chatgpt_sheet_path):
        img_cg = Image.open(chatgpt_sheet_path).convert("RGBA")
        target_w = W - 80
        target_h = int(img_cg.height * (target_w / img_cg.width))
        if target_h > 1200:
            target_h = 1200
            target_w = int(img_cg.width * (target_h / img_cg.height))
        img_cg_resized = img_cg.resize((target_w, target_h), Image.Resampling.LANCZOS)
        board.paste(img_cg_resized, ((W - target_w) // 2, 160))
        bottom_y = 160 + target_h + 30
    else:
        bottom_y = 600

    # Section 2: In-Engine Godot 3D Real-Time Renders
    draw.rectangle([40, bottom_y, W - 40, bottom_y + 40], fill=(30, 33, 40, 255))
    draw.text((50, bottom_y + 6), "2. GODOT IN-ENGINE REAL-TIME 3D RENDERS (BASE HS-7 vs COURIER BIKE vs SILENT CORE INFILTRATOR)", fill=(255, 85, 0, 255), font=font_label)

    render_y = bottom_y + 55
    render_w = (W - 120) // 3
    render_h = H - render_y - 40

    render_paths = [
        (render_front_path, "32° GAMEPLAY VIEW (BASE vs BIKE vs SILENT CORE)"),
        (render_rear_path, "32° REAR VIEW (SATCHEL & DORSAL MARKINGS)"),
        (render_top_path, "90° OVERHEAD CHINATOWN WARS HEADING READ")
    ]

    for idx, (rpath, label) in enumerate(render_paths):
        rx = 40 + idx * (render_w + 20)
        draw.rectangle([rx, render_y, rx + render_w, render_y + render_h], fill=(20, 22, 26, 255), outline=(50, 55, 65, 255), width=2)
        if os.path.exists(rpath):
            rim = Image.open(rpath).convert("RGBA")
            scale = min(render_w / rim.width, (render_h - 45) / rim.height)
            nw, nh = int(rim.width * scale), int(rim.height * scale)
            rim_resized = rim.resize((nw, nh), Image.Resampling.LANCZOS)
            board.paste(rim_resized, (rx + (render_w - nw) // 2, render_y + 40 + (render_h - 45 - nh) // 2))
        draw.rectangle([rx, render_y, rx + render_w, render_y + 35], fill=(28, 30, 36, 255))
        draw.text((rx + 15, render_y + 8), label, fill=(230, 235, 245, 255), font=font_tag)

    os.makedirs(os.path.dirname(out_board_path), exist_ok=True)
    board.save(out_board_path, format="PNG")
    board.save(artifact_board_path, format="PNG")
    print(f"Assembled alt skin presentation board:\n  {out_board_path}\n  {artifact_board_path}")

if __name__ == '__main__':
    main()
