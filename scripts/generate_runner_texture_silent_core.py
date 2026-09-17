#!/usr/bin/env python3
"""
scripts/generate_runner_texture_silent_core.py
Generates the 2048x2048 texture atlas for the 'Silent Core Infiltrator' (Archive Ghost) alternate skin,
matching the concept sheet created with ChatGPT.
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

def draw_hazard_stripes(draw, x1, y1, x2, y2, stripe_w=24, col1=(255, 85, 0), col2=(20, 22, 25)):
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

def draw_chevron(draw, cx, cy, w, h, thickness, color):
    pts = [
        (cx - w // 2, cy - h // 2),
        (cx, cy),
        (cx + w // 2, cy - h // 2),
        (cx + w // 2, cy - h // 2 + thickness),
        (cx, cy + thickness),
        (cx - w // 2, cy - h // 2 + thickness),
    ]
    draw.polygon(pts, fill=color)

def main():
    W, H = 2048, 2048
    img = Image.new("RGBA", (W, H), (27, 30, 35, 255))
    draw = ImageDraw.Draw(img)

    COL_JACKET_DARK  = (27, 30, 35, 255)     # Archive Charcoal #1B1E23
    COL_JACKET_PANEL = (38, 42, 49, 255)     # Gunmetal dark panel
    COL_TEE_DARK     = (18, 19, 22, 255)     # Compression shirt
    COL_SIGNAL_ORG   = (255, 85, 0, 255)     # Signal Orange #FF5500
    COL_BONE         = (215, 209, 197, 255)  # Salvage Bone #D7D1C5
    COL_SKIN         = (222, 168, 138, 255)  # Stylized skin tone
    COL_SKIN_SHADOW  = (188, 132, 104, 255)  # Shaded skin
    COL_HAIR         = (20, 21, 24, 255)     # Undercut spiky dark hair
    COL_GUNMETAL     = (74, 79, 86, 255)     # Gunmetal Steel #4A4F56
    COL_PANTS        = (22, 24, 28, 255)     # Infiltrator charcoal jogger
    COL_KNEE_ARMOR   = (65, 68, 75, 255)     # Impact-rated gunmetal knee armor
    COL_CYAN_GLOW    = (0, 229, 255, 255)    # Memory Cyan #00E5FF
    COL_STENCIL_WHT  = (242, 244, 248, 255)  # Crisp vector stencil white

    font_xl = get_font(68, bold=True)
    font_lg = get_font(46, bold=True)
    font_md = get_font(32, bold=True)
    font_sm = get_font(22, bold=True)

    # 1. JACKET BODY (41, 41, 573, 778) - SC-RELAY // DZ-03
    j_x1, j_y1, j_x2, j_y2 = 41, 41, 573, 778
    draw.rectangle([j_x1, j_y1, j_x2, j_y2], fill=COL_JACKET_DARK)
    draw.rectangle([j_x1 + 40, j_y1 + 60, j_x2 - 40, j_y2 - 60], fill=COL_JACKET_PANEL)
    draw.line([j_x1 + 38, j_y1 + 60, j_x1 + 38, j_y2 - 60], fill=(15, 16, 18, 255), width=4)
    draw.line([j_x2 - 38, j_y1 + 60, j_x2 - 38, j_y2 - 60], fill=(15, 16, 18, 255), width=4)
    draw.rectangle([j_x1 + 250, j_y1 + 40, j_x1 + 274, j_y2 - 40], fill=COL_GUNMETAL)
    for zy in range(j_y1 + 50, j_y2 - 50, 14):
        draw.line([j_x1 + 250, zy, j_x1 + 274, zy], fill=(30, 32, 38, 255), width=2)
    draw.rectangle([j_x1 + 80, j_y1 + 140, j_x1 + 230, j_y1 + 190], fill=(18, 20, 24, 255))
    draw.rectangle([j_x1 + 80, j_y1 + 140, j_x1 + 90, j_y1 + 190], fill=COL_SIGNAL_ORG)
    draw.text((j_x1 + 98, j_y1 + 145), "SC-RELAY", fill=COL_STENCIL_WHT, font=font_sm)
    draw.text((j_x1 + 98, j_y1 + 165), "// DZ-03", fill=COL_SIGNAL_ORG, font=font_sm)

    # 2. INNER TEE & STRAPS (614, 41, 983, 410)
    t_x1, t_y1, t_x2, t_y2 = 614, 41, 983, 410
    draw.rectangle([t_x1, t_y1, t_x2, t_y2], fill=COL_TEE_DARK)
    for ry in range(t_y1 + 8, t_y2, 12):
        draw.line([t_x1, ry, t_x2, ry], fill=(26, 28, 32, 255), width=3)
    s_x1, s_y1, s_x2, s_y2 = t_x1 + 20, t_y1 + 240, t_x2 - 20, t_y2 - 20
    draw.rectangle([s_x1, s_y1, s_x2, s_y2], fill=(15, 16, 18, 255))
    draw.line([s_x1, s_y1 + 2, s_x2, s_y1 + 2], fill=COL_SIGNAL_ORG, width=4)
    draw.line([s_x1, s_y2 - 2, s_x2, s_y2 - 2], fill=COL_SIGNAL_ORG, width=4)

    # 3. SOLID SIGNAL ORANGE / LAPEL LINING (1024, 41, 1393, 410)
    o_x1, o_y1, o_x2, o_y2 = 1024, 41, 1393, 410
    draw.rectangle([o_x1, o_y1, o_x2, o_y2], fill=COL_SIGNAL_ORG)
    draw_hazard_stripes(draw, o_x1 + 20, o_y2 - 120, o_x2 - 20, o_y2 - 20, stripe_w=18, col1=COL_SIGNAL_ORG, col2=COL_JACKET_DARK)

    # 4. GTA SKIN TONE (1434, 41, 1802, 410)
    sk_x1, sk_y1, sk_x2, sk_y2 = 1434, 41, 1802, 410
    draw.rectangle([sk_x1, sk_y1, sk_x2, sk_y2], fill=COL_SKIN)
    draw.rectangle([sk_x1, sk_y2 - 100, sk_x2, sk_y2], fill=COL_SKIN_SHADOW)

    # 5. HAIR & COMM HEADSET (41, 819, 410, 1188)
    h_x1, h_y1, h_x2, h_y2 = 41, 819, 410, 1188
    draw.rectangle([h_x1, h_y1, h_x2, h_y2], fill=COL_HAIR)
    for hy in range(h_y1 + 10, h_y2, 20):
        draw.line([h_x1, hy, h_x2, hy], fill=(30, 32, 36, 255), width=3)

    # 6. METALS & COBRA BUCKLE (451, 819, 778, 1188)
    m_x1, m_y1, m_x2, m_y2 = 451, 819, 778, 1188
    draw.rectangle([m_x1, m_y1, m_x2, m_y2], fill=COL_GUNMETAL)
    draw.rectangle([m_x1 + 30, m_y1 + 40, m_x2 - 30, m_y1 + 180], fill=(35, 38, 44, 255))
    draw.rectangle([m_x1 + 60, m_y1 + 60, m_x2 - 60, m_y1 + 160], fill=COL_GUNMETAL)
    draw.text((m_x1 + 75, m_y1 + 95), "COBRA", fill=(20, 22, 25, 255), font=font_md)
    draw.rectangle([m_x1 + 10, m_y1 + 90, m_x1 + 35, m_y1 + 130], fill=COL_SIGNAL_ORG)
    draw.rectangle([m_x2 - 35, m_y1 + 90, m_x2 - 10, m_y1 + 130], fill=COL_SIGNAL_ORG)

    # 7. CARGO PANTS & KNEE ARMOR (819, 451, 1393, 1188)
    p_x1, p_y1, p_x2, p_y2 = 819, 451, 1393, 1188
    draw.rectangle([p_x1, p_y1, p_x2, p_y2], fill=COL_PANTS)
    draw.rectangle([p_x1 + 40, p_y1 + 50, p_x1 + 360, p_y1 + 350], fill=(16, 18, 22, 255))
    draw.rectangle([p_x1 + 40, p_y1 + 50, p_x1 + 360, p_y1 + 130], fill=(30, 33, 38, 255))
    draw.line([p_x1 + 40, p_y1 + 130, p_x1 + 360, p_y1 + 130], fill=COL_SIGNAL_ORG, width=6)
    draw.text((p_x1 + 70, p_y1 + 75), "SILENT // CARGO", fill=COL_STENCIL_WHT, font=font_sm)
    draw.rectangle([p_x1 + 400, p_y1 + 50, p_x2 - 40, p_y1 + 350], fill=COL_KNEE_ARMOR)
    draw_chevron(draw, (p_x1 + 400 + p_x2 - 40) // 2, p_y1 + 150, 140, 60, 20, COL_SIGNAL_ORG)
    draw.text((p_x1 + 430, p_y1 + 250), "GHOST-03", fill=COL_STENCIL_WHT, font=font_md)

    # 8. SNEAKER MIDSOLE (1434, 451, 2007, 778) - Salvage Bone #D7D1C5
    sm_x1, sm_y1, sm_x2, sm_y2 = 1434, 451, 2007, 778
    draw.rectangle([sm_x1, sm_y1, sm_x2, sm_y2], fill=COL_BONE)
    for lx in range(sm_x1 + 60, sm_x2 - 60, 80):
        draw.line([lx, sm_y1 + 40, lx + 30, sm_y2 - 40], fill=(185, 180, 170, 255), width=4)
    draw.rectangle([sm_x1 + 100, sm_y1 + 120, sm_x1 + 360, sm_y1 + 180], fill=(150, 145, 138, 255))
    draw.text((sm_x1 + 120, sm_y1 + 132), "SALVAGE // SC", fill=COL_STENCIL_WHT, font=font_md)

    # 9. SNEAKER TREAD LUGS (1434, 819, 2007, 1188) - Signal Orange
    st_x1, st_y1, st_x2, st_y2 = 1434, 819, 2007, 1188
    draw.rectangle([st_x1, st_y1, st_x2, st_y2], fill=COL_SIGNAL_ORG)
    for gx in range(st_x1 + 40, st_x2 - 40, 60):
        for gy in range(st_y1 + 40, st_y2 - 40, 70):
            draw.rectangle([gx, gy, gx + 36, gy + 45], fill=(22, 24, 28, 255))

    # 10. SATCHEL FLAP & MEMORY COURIER // GHOST ROUTE STENCIL (41, 1229, 983, 2007)
    sf_x1, sf_y1, sf_x2, sf_y2 = 41, 1229, 983, 2007
    draw.rectangle([sf_x1, sf_y1, sf_x2, sf_y2], fill=(20, 22, 26, 255))
    draw.rectangle([sf_x1 + 20, sf_y1 + 20, sf_x2 - 20, sf_y2 - 20], outline=COL_SIGNAL_ORG, width=12)
    draw.rectangle([sf_x1 + 50, sf_y1 + 60, sf_x2 - 50, sf_y1 + 240], fill=(14, 15, 18, 255))
    tri_pts = [
        (sf_x1 + 130, sf_y1 + 190),
        (sf_x1 + 190, sf_y1 + 90),
        (sf_x1 + 250, sf_y1 + 190)
    ]
    draw.polygon(tri_pts, fill=COL_SIGNAL_ORG)
    inner_tri = [
        (sf_x1 + 155, sf_y1 + 175),
        (sf_x1 + 190, sf_y1 + 120),
        (sf_x1 + 225, sf_y1 + 175)
    ]
    draw.polygon(inner_tri, fill=(14, 15, 18, 255))
    draw.text((sf_x1 + 280, sf_y1 + 80), "MEMORY COURIER //", fill=COL_STENCIL_WHT, font=font_xl)
    draw.text((sf_x1 + 280, sf_y1 + 150), "GHOST ROUTE //", fill=COL_SIGNAL_ORG, font=font_xl)
    draw.line([sf_x1 + 50, sf_y1 + 280, sf_x2 - 50, sf_y1 + 280], fill=COL_SIGNAL_ORG, width=6)
    draw.text((sf_x1 + 60, sf_y1 + 310), "SPEC: SC-RELAY // FORBIDDEN FRAGMENT RUNNER", fill=COL_STENCIL_WHT, font=font_md)
    draw.text((sf_x1 + 60, sf_y1 + 370), "SECTOR: SILENT CORE // GHOST CHECKPOINT ROUTE", fill=(170, 175, 185, 255), font=font_sm)
    draw.text((sf_x1 + 60, sf_y1 + 420), "STATUS: INFILTRATING // ZERO FOOTPRINT", fill=(170, 175, 185, 255), font=font_sm)
    draw.rectangle([sf_x1 + 160, sf_y1 + 470, sf_x1 + 240, sf_y2 - 40], fill=(14, 15, 18, 255))
    draw.rectangle([sf_x1 + 185, sf_y1 + 470, sf_x1 + 215, sf_y2 - 40], fill=COL_SIGNAL_ORG)
    draw.rectangle([sf_x2 - 240, sf_y1 + 470, sf_x2 - 160, sf_y2 - 40], fill=(14, 15, 18, 255))
    draw.rectangle([sf_x2 - 215, sf_y1 + 470, sf_x2 - 185, sf_y2 - 40], fill=COL_SIGNAL_ORG)
    draw_hazard_stripes(draw, sf_x1 + 50, sf_y2 - 180, sf_x2 - 50, sf_y2 - 80, stripe_w=28, col1=COL_SIGNAL_ORG, col2=COL_JACKET_DARK)

    # 11. DORSAL SPINE HAZARD CHEVRONS (1024, 1229, 1475, 2007)
    ds_x1, ds_y1, ds_x2, ds_y2 = 1024, 1229, 1475, 2007
    draw.rectangle([ds_x1, ds_y1, ds_x2, ds_y2], fill=(22, 24, 28, 255))
    draw.rectangle([ds_x1 + 40, ds_y1 + 30, ds_x2 - 40, ds_y2 - 30], fill=(14, 15, 18, 255))
    draw.rectangle([ds_x1 + 60, ds_y1 + 50, ds_x2 - 60, ds_y1 + 140], fill=COL_SIGNAL_ORG)
    draw.text((ds_x1 + 90, ds_y1 + 65), "SC-03", fill=(14, 15, 18, 255), font=font_xl)
    spine_cx = (ds_x1 + ds_x2) // 2
    for cy in range(ds_y1 + 220, ds_y2 - 220, 110):
        draw_chevron(draw, spine_cx, cy, 220, 70, 36, COL_SIGNAL_ORG)
    draw.rectangle([ds_x1 + 60, ds_y2 - 190, ds_x2 - 60, ds_y2 - 50], fill=(18, 20, 24, 255))
    draw.text((ds_x1 + 80, ds_y2 - 170), "RIDE.", fill=COL_STENCIL_WHT, font=font_md)
    draw.text((ds_x1 + 80, ds_y2 - 130), "ROUTE.", fill=COL_SIGNAL_ORG, font=font_md)
    draw.text((ds_x1 + 80, ds_y2 - 90), "REMEMBER.", fill=COL_STENCIL_WHT, font=font_md)

    # 12. CYAN COMM HUD SCREEN (1516, 1229, 2007, 1741)
    c_x1, c_y1, c_x2, c_y2 = 1516, 1229, 2007, 1741
    draw.rectangle([c_x1, c_y1, c_x2, c_y2], fill=(0, 20, 30, 255))
    draw.rectangle([c_x1 + 15, c_y1 + 15, c_x2 - 15, c_y2 - 15], outline=COL_CYAN_GLOW, width=6)
    for gy in range(c_y1 + 30, c_y2 - 30, 40):
        draw.line([c_x1 + 20, gy, c_x2 - 20, gy], fill=(0, 65, 90, 255), width=2)
    import math
    wave_pts = []
    for wx in range(c_x1 + 30, c_x2 - 30, 10):
        ang = (wx - c_x1) * 0.05
        wy = c_y1 + 180 + int(math.sin(ang) * 45 + math.sin(ang * 2.5) * 20)
        wave_pts.append((wx, wy))
    for i in range(len(wave_pts) - 1):
        draw.line([wave_pts[i], wave_pts[i+1]], fill=COL_CYAN_GLOW, width=4)
    draw.text((c_x1 + 35, c_y1 + 45), "[ARCHIVE SYNC... // 7A3F]", fill=COL_CYAN_GLOW, font=font_md)
    draw.text((c_x1 + 35, c_y1 + 270), "ROUTE: A7 // MEMORY OK", fill=COL_STENCIL_WHT, font=font_lg)
    draw.text((c_x1 + 35, c_y1 + 350), "CELL: ANTI-QUOTA // ACTIVE", fill=COL_CYAN_GLOW, font=font_sm)
    draw.text((c_x1 + 35, c_y1 + 390), "OPERATOR: ARCHIVE GHOST", fill=(180, 240, 255, 255), font=font_sm)

    # 13. CYAN VISOR / HUD EMISSION (1516, 1761, 2007, 2007)
    v_x1, v_y1, v_x2, v_y2 = 1516, 1761, 2007, 2007
    draw.rectangle([v_x1, v_y1, v_x2, v_y2], fill=COL_CYAN_GLOW)
    draw.rectangle([v_x1 + 40, v_y1 + 60, v_x2 - 40, v_y2 - 60], fill=(180, 250, 255, 255))
    draw.text((v_x1 + 60, v_y1 + 80), "AR-GHOST // SYNCED", fill=(0, 60, 80, 255), font=font_lg)

    target_godot = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter/tex_runner_atlas_silent_core.png"
    target_ref = "/Users/bobbyinthelobby/{art/docs/visual_direction/references/runner_silent_core_atlas.png"
    
    os.makedirs(os.path.dirname(target_godot), exist_ok=True)
    os.makedirs(os.path.dirname(target_ref), exist_ok=True)
    
    img.save(target_godot, format="PNG")
    img.save(target_ref, format="PNG")
    print(f"Generated Silent Core Infiltrator atlas:")
    print(f"  - {target_godot}")
    print(f"  - {target_ref}")

if __name__ == '__main__':
    main()
