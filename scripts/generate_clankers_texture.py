#!/usr/bin/env python3
"""
scripts/generate_clankers_texture.py
Generates a pristine 2048x2048 vector-sharp texture atlas for the Clankers:
- Scrap Worker Bot (1.9m)
- Utility Crawler Bot (0.6m)
Matches docs/visual_direction/references/clankers_concept_sheet.png exactly.
"""

import os
import math
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

def draw_hazard_stripes(draw, x1, y1, x2, y2, stripe_w=24, col1=(229, 169, 34, 255), col2=(28, 30, 34, 255)):
    w = x2 - x1
    h = y2 - y1
    draw.rectangle([x1, y1, x2, y2], fill=col2)
    for offset in range(-h, w + h, stripe_w * 2):
        pts = [
            (x1 + offset, y1),
            (x1 + offset + stripe_w, y1),
            (x1 + offset + stripe_w - h, y2),
            (x1 + offset - h, y2)
        ]
        draw.polygon(pts, fill=col1)

def main():
    W, H = 2048, 2048
    img = Image.new("RGBA", (W, H), (24, 26, 30, 255))
    draw = ImageDraw.Draw(img)

    # Palette
    COL_CAST_IRON   = (32, 35, 40, 255)     # Dark weathered cast-iron chassis
    COL_STEEL_DARK  = (45, 48, 55, 255)     # Structural steel
    COL_STEEL_LIGHT = (140, 145, 155, 255)  # Hydraulic pistons / shiny steel
    COL_CRANE_YEL   = (229, 169, 34, 255)   # Industrial machinery yellow #E5A922
    COL_YEL_SHADOW  = (185, 130, 20, 255)   # Shaded machinery yellow
    COL_BONE_WHITE  = (215, 209, 197, 255)  # Off-white weathered panel #D7D1C5
    COL_SAFETY_ORG  = (255, 85, 0, 255)     # Signal safety orange #FF5500
    COL_AMBER_GLOW  = (255, 170, 0, 255)    # Sensor optic amber #FFAA00
    COL_CYAN_GLOW   = (0, 229, 255, 255)    # Sensor optic cyan #00E5FF
    COL_TREAD_DARK  = (20, 21, 24, 255)     # Heavy vulcanized rubber tread
    COL_TEXT_DARK   = (20, 22, 25, 255)     # Stencil dark ink
    COL_STENCIL_WHT = (245, 248, 252, 255)  # Stencil white

    font_xl = get_font(64, bold=True)
    font_lg = get_font(44, bold=True)
    font_md = get_font(30, bold=True)
    font_sm = get_font(20, bold=True)

    # 1. SCRAP WORKER TORSO FRONT (41, 41, 573, 778) - UNIT-404 // SCRAP SORT
    t_x1, t_y1, t_x2, t_y2 = 41, 41, 573, 778
    draw.rectangle([t_x1, t_y1, t_x2, t_y2], fill=COL_BONE_WHITE)
    draw.rectangle([t_x1 + 25, t_y1 + 25, t_x2 - 25, t_y2 - 25], outline=(150, 145, 135, 255), width=6)
    # Rust stains & scratches
    for sy in range(t_y1 + 60, t_y2 - 60, 35):
        draw.line([t_x1 + 30, sy, t_x1 + 60, sy + 15], fill=(130, 85, 40, 180), width=3)
    draw.text((t_x1 + 60, t_y1 + 100), "UNIT-404", fill=COL_TEXT_DARK, font=font_xl)
    draw.text((t_x1 + 60, t_y1 + 190), "SCRAP SORT", fill=COL_TEXT_DARK, font=font_lg)
    draw.line([t_x1 + 60, t_y1 + 260, t_x2 - 60, t_y1 + 260], fill=COL_SAFETY_ORG, width=6)
    draw.text((t_x1 + 60, t_y1 + 290), "DISPATCH: BURNSIDE // BAY-01", fill=COL_TEXT_DARK, font=font_sm)
    draw.text((t_x1 + 60, t_y1 + 330), "REPURPOSED HEAVY CHASSIS", fill=(90, 85, 75, 255), font=font_sm)

    # 2. SCRAP WORKER TORSO BACK (614, 41, 1146, 778) - ASSET OF BURNSIDE SALVAGE
    b_x1, b_y1, b_x2, b_y2 = 614, 41, 1146, 778
    draw.rectangle([b_x1, b_y1, b_x2, b_y2], fill=COL_CAST_IRON)
    draw.rectangle([b_x1 + 30, b_y1 + 30, b_x2 - 30, b_y1 + 300], fill=COL_BONE_WHITE)
    draw.text((b_x1 + 60, b_y1 + 60), "ASSET OF", fill=COL_TEXT_DARK, font=font_md)
    draw.text((b_x1 + 60, b_y1 + 110), "BURNSIDE", fill=COL_SAFETY_ORG, font=font_xl)
    draw.text((b_x1 + 60, b_y1 + 190), "SALVAGE", fill=COL_TEXT_DARK, font=font_xl)
    draw_hazard_stripes(draw, b_x1 + 30, b_y1 + 260, b_x2 - 30, b_y1 + 300, stripe_w=20)
    # Exhaust / Battery compartment
    draw.rectangle([b_x1 + 40, b_y1 + 340, b_x2 - 40, b_y2 - 40], fill=(22, 24, 28, 255))
    for ey in range(b_y1 + 360, b_y2 - 60, 25):
        draw.line([b_x1 + 60, ey, b_x2 - 60, ey], fill=COL_STEEL_DARK, width=6)

    # 3. SATIRICAL WARNING PLATE (1188, 41, 1597, 410)
    w_x1, w_y1, w_x2, w_y2 = 1188, 41, 1597, 410
    draw.rectangle([w_x1, w_y1, w_x2, w_y2], fill=(220, 218, 212, 255), outline=(40, 42, 48, 255), width=8)
    draw.rectangle([w_x1 + 20, w_y1 + 20, w_x2 - 20, w_y1 + 90], fill=(210, 30, 30, 255))
    draw.text((w_x1 + 40, w_y1 + 32), "▲ WARNING", fill=(255, 255, 255, 255), font=font_md)
    draw.text((w_x1 + 30, w_y1 + 120), "TAMPERING VOIDS", fill=COL_TEXT_DARK, font=font_md)
    draw.text((w_x1 + 30, w_y1 + 170), "REMAINING ORGAN", fill=COL_TEXT_DARK, font=font_md)
    draw.text((w_x1 + 30, w_y1 + 220), "LEASE CONTRACT.", fill=COL_TEXT_DARK, font=font_md)
    draw.text((w_x1 + 30, w_y1 + 290), "BURNSIDE MUNICIPAL QUOTA", fill=(120, 40, 40, 255), font=font_sm)

    # 4. SENSOR TURRET & OPTICS (1638, 41, 2007, 410)
    o_x1, o_y1, o_x2, o_y2 = 1638, 41, 2007, 410
    draw.rectangle([o_x1, o_y1, o_x2, o_y2], fill=COL_CAST_IRON)
    # Amber primary lens
    draw.ellipse([o_x1 + 40, o_y1 + 40, o_x1 + 180, o_y1 + 180], fill=COL_AMBER_GLOW, outline=(120, 70, 0, 255), width=6)
    draw.ellipse([o_x1 + 70, o_y1 + 70, o_x1 + 150, o_y1 + 150], fill=(255, 230, 160, 255))
    # Cyan secondary lens
    draw.ellipse([o_x1 + 210, o_y1 + 70, o_x1 + 310, o_y1 + 170], fill=COL_CYAN_GLOW, outline=(0, 90, 110, 255), width=5)
    draw.ellipse([o_x1 + 235, o_y1 + 95, o_x1 + 285, o_y1 + 145], fill=(200, 250, 255, 255))
    draw.text((o_x1 + 40, o_y1 + 240), "OPTIC // SENSOR-4", fill=COL_STENCIL_WHT, font=font_md)
    draw.text((o_x1 + 40, o_y1 + 300), "CALIBRATED: 60Hz LiDAR", fill=(160, 165, 175, 255), font=font_sm)

    # 5. INDUSTRIAL CRANE YELLOW LIMBS & ARM (41, 819, 573, 1393)
    y_x1, y_y1, y_x2, y_y2 = 41, 819, 573, 1393
    draw.rectangle([y_x1, y_y1, y_x2, y_y2], fill=COL_CRANE_YEL)
    draw.rectangle([y_x1 + 40, y_y1 + 60, y_x2 - 40, y_y2 - 60], fill=COL_YEL_SHADOW)
    draw.text((y_x1 + 80, y_y1 + 100), "04", fill=COL_TEXT_DARK, font=font_xl)
    draw_hazard_stripes(draw, y_x1 + 40, y_y2 - 160, y_x2 - 40, y_y2 - 60, stripe_w=24)

    # 6. HYDRAULIC PISTONS & POLISHED STEEL (614, 819, 1146, 1393)
    p_x1, p_y1, p_x2, p_y2 = 614, 819, 1146, 1393
    draw.rectangle([p_x1, p_y1, p_x2, p_y2], fill=COL_STEEL_DARK)
    for px in range(p_x1 + 60, p_x2 - 60, 90):
        draw.rectangle([px, p_y1 + 40, px + 50, p_y2 - 40], fill=COL_STEEL_LIGHT)
        draw.line([px + 10, p_y1 + 40, px + 10, p_y2 - 40], fill=(240, 245, 255, 255), width=4)

    # 7. UTILITY CRAWLER CHASSIS & BURNSIDE LOGO (1188, 451, 2007, 1188)
    c_x1, c_y1, c_x2, c_y2 = 1188, 451, 2007, 1188
    draw.rectangle([c_x1, c_y1, c_x2, c_y2], fill=COL_CRANE_YEL)
    draw.rectangle([c_x1 + 30, c_y1 + 30, c_x2 - 30, c_y2 - 30], outline=(40, 42, 48, 255), width=8)
    draw.rectangle([c_x1 + 60, c_y1 + 80, c_x1 + 420, c_y1 + 220], fill=COL_CAST_IRON)
    draw.text((c_x1 + 80, c_y1 + 105), "BURNSIDE", fill=COL_CRANE_YEL, font=font_xl)
    draw.text((c_x1 + 80, c_y1 + 260), "SALVAGE", fill=COL_TEXT_DARK, font=font_xl)
    # Caution triangle
    tri_c = [
        (c_x1 + 550, c_y1 + 220),
        (c_x1 + 620, c_y1 + 90),
        (c_x1 + 690, c_y1 + 220)
    ]
    draw.polygon(tri_c, fill=COL_SAFETY_ORG)
    draw.text((c_x1 + 610, c_y1 + 130), "!", fill=(255, 255, 255, 255), font=font_xl)
    draw_hazard_stripes(draw, c_x1 + 50, c_y2 - 140, c_x2 - 50, c_y2 - 50, stripe_w=28)

    # 8. CRAWLER BATTERY CORE CRADLE & CYAN GLOW (41, 1434, 983, 2007)
    bc_x1, bc_y1, bc_x2, bc_y2 = 41, 1434, 983, 2007
    draw.rectangle([bc_x1, bc_y1, bc_x2, bc_y2], fill=COL_CAST_IRON)
    draw.rectangle([bc_x1 + 30, bc_y1 + 30, bc_x2 - 30, bc_y2 - 30], fill=(15, 17, 20, 255))
    # Battery cells with cyan glow
    for by in range(bc_y1 + 80, bc_y2 - 160, 100):
        draw.rectangle([bc_x1 + 80, by, bc_x2 - 80, by + 60], fill=(0, 40, 55, 255), outline=COL_CYAN_GLOW, width=4)
        draw.line([bc_x1 + 90, by + 30, bc_x2 - 90, by + 30], fill=COL_CYAN_GLOW, width=6)
    draw.text((bc_x1 + 80, bc_y2 - 120), "CORE DOCK // 480V ACTIVE", fill=COL_CYAN_GLOW, font=font_lg)

    # 9. HEAVY DUTY TREAD RUBBER (1024, 1434, 2007, 2007)
    tr_x1, tr_y1, tr_x2, tr_y2 = 1024, 1434, 2007, 2007
    draw.rectangle([tr_x1, tr_y1, tr_x2, tr_y2], fill=COL_TREAD_DARK)
    for ty in range(tr_y1 + 30, tr_y2 - 30, 60):
        draw.rectangle([tr_x1 + 40, ty, tr_x2 - 40, ty + 35], fill=(36, 38, 44, 255))
        draw.rectangle([tr_x1 + 100, ty + 8, tr_x1 + 250, ty + 27], fill=(18, 19, 22, 255))
        draw.rectangle([tr_x2 - 250, ty + 8, tr_x2 - 100, ty + 27], fill=(18, 19, 22, 255))

    target_godot = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter/tex_clankers_atlas.png"
    target_ref = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/clankers_atlas.png"

    os.makedirs(os.path.dirname(target_godot), exist_ok=True)
    os.makedirs(os.path.dirname(target_ref), exist_ok=True)

    img.save(target_godot, format="PNG")
    img.save(target_ref, format="PNG")
    print("Generated clean 2048x2048 Clankers vector atlas:")
    print(f"  - {target_godot}")
    print(f"  - {target_ref}")

if __name__ == '__main__':
    main()
