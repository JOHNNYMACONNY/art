#!/usr/bin/env python3
"""
scripts/assemble_clankers_eval_board.py
Assembles blind evaluation board for the Clankers (Scrap Worker & Utility Crawler):
Top Section: Concept Art Benchmark (Candidate B)
Bottom Section: In-Engine 3D Real-Time Godot Renders (Candidate A)
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
    concept_sheet_path = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/clankers_concept_sheet.png"
    render_front_path = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/clankers_render_32deg.png"
    render_rear_path = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/clankers_render_rear_32deg.png"
    render_top_path = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/clankers_render_topdown.png"

    out_board_path = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/blind_eval_clankers.png"
    artifact_board_path = "/Users/bobbyinthelobby/.gemini/antigravity/brain/beee1f70-b0b4-4831-a112-9a9b7c603049/blind_eval_clankers.png"

    W, H = 2560, 2200
    board = Image.new("RGBA", (W, H), (14, 15, 18, 255))
    draw = ImageDraw.Draw(board)

    font_title = get_font(44, bold=True)
    font_label = get_font(30, bold=True)
    font_tag = get_font(20, bold=True)

    # Header
    draw.rectangle([0, 0, W, 90], fill=(22, 24, 30, 255))
    draw.text((40, 22), "CLANKERS GAUNTLET EVALUATION // SCRAP WORKER & UTILITY CRAWLER", fill=(245, 248, 255, 255), font=font_title)
    draw.text((W - 650, 32), "GEARS DISTRICT SCRAP-SCI-FI PIPELINE", fill=(229, 169, 34, 255), font=font_tag)

    # Section 1: Concept Benchmark (Candidate B)
    draw.rectangle([40, 110, W - 40, 150], fill=(30, 33, 40, 255))
    draw.text((50, 118), "CANDIDATE B: PRODUCTION CONCEPT MODEL SHEET (REPURPOSED INDUSTRIAL SCRAP BOTS)", fill=(0, 229, 255, 255), font=font_label)

    if os.path.exists(concept_sheet_path):
        img_cg = Image.open(concept_sheet_path).convert("RGBA")
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

    # Section 2: In-Engine Real-Time Renders (Candidate A)
    draw.rectangle([40, bottom_y, W - 40, bottom_y + 40], fill=(30, 33, 40, 255))
    draw.text((50, bottom_y + 6), "CANDIDATE A: GODOT 3D REAL-TIME ENGINE RENDERS (SCRAP WORKER + UTILITY CRAWLER + RUNNER)", fill=(229, 169, 34, 255), font=font_label)

    render_y = bottom_y + 55
    render_w = (W - 120) // 3
    render_h = H - render_y - 40

    render_paths = [
        (render_front_path, "32° GAMEPLAY FRONT VIEW (RUNNER SCALE vs SCRAP WORKER vs CRAWLER)"),
        (render_rear_path, "32° REAR VIEW (EXHAUST, BURNSIDE STENCIL & BATTERY CRADLE)"),
        (render_top_path, "90° TOP-DOWN OVERHEAD READABILITY")
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
    print(f"Assembled clankers evaluation board:\n  {out_board_path}\n  {artifact_board_path}")

if __name__ == '__main__':
    main()
