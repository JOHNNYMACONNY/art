"""
scripts/generate_vehicle_modular_textures.py
Generates modular vehicle textures following GTA / open-world industry standard:
1. tex_vehicle_trim.png (Shared 2048x2048 trim sheet for headlights, taillights, grilles, plates, badges)
2. tex_coupe_livery.png (Burnside orange base with discrete panel UV regions: Hood, Roof, Trunk, Left Side, Right Side, Chin)
3. tex_hauler_livery.png (Industrial yellow base with discrete panel UV regions: Bed Sides, Cab Doors L/R, Tailgate, Visor)
4. tex_security_interceptor_livery.png (Pursuit dark navy base with discrete panel UV regions: Hood, Roof, Trunk, Left Side, Right Side)
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter"
os.makedirs(OUT_DIR, exist_ok=True)

def get_font(size):
    for path in [
        "/System/Library/Fonts/Supplemental/Impact.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                pass
    return ImageFont.load_default()

def get_mono_font(size):
    for path in [
        "/System/Library/Fonts/Supplemental/Courier New Bold.ttf",
        "/System/Library/Fonts/Menlo.ttc",
        "/System/Library/Fonts/SFNSMono.ttf",
    ]:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                pass
    return ImageFont.load_default()

def draw_chevrons(draw, x0, y0, x1, y1, width=32, col1=(245, 180, 0, 255), col2=(20, 20, 20, 255)):
    h = y1 - y0
    for x in range(x0 - h, x1 + h, width * 2):
        points = [(x, y0), (x + width, y0), (x + width + h, y1), (x + h, y1)]
        draw.polygon(points, fill=col1)
        points2 = [(x + width, y0), (x + width * 2, y0), (x + width * 2 + h, y1), (x + width + h, y1)]
        draw.polygon(points2, fill=col2)

# ==========================================
# 1. SHARED VEHICLE TRIM SHEET (2048x2048)
# ==========================================
def generate_trim_sheet():
    img = Image.new("RGBA", (2048, 2048), (22, 24, 28, 255))
    draw = ImageDraw.Draw(img)

    # QUADRANT 1 (0, 0, 1024, 1024): HEADLIGHTS & FRONT LAMPS
    # Round Quad Lamps (Muscle Coupe) -> (0, 0, 512, 512)
    draw.rectangle([10, 10, 502, 502], fill=(12, 13, 15, 255), outline=(60, 65, 75, 255), width=4)
    for cx in (150, 360):
        cy = 256
        r = 95
        draw.ellipse([cx - r - 12, cy - r - 12, cx + r + 12, cy + r + 12], fill=(180, 185, 195, 255))
        draw.ellipse([cx - r - 4, cy - r - 4, cx + r + 4, cy + r + 4], fill=(80, 85, 95, 255))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(230, 235, 245, 255))
        for step in range(r - 15, 10, -18):
            draw.ellipse([cx - step, cy - step, cx + step, cy + step], outline=(140, 145, 160, 255), width=3)
        draw.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], fill=(255, 245, 200, 255), outline=(210, 160, 50, 255), width=3)

    # Rectangular Pursuit Headlights (Interceptor) -> (512, 0, 1024, 512)
    draw.rectangle([522, 10, 1014, 502], fill=(15, 16, 18, 255), outline=(50, 55, 65, 255), width=4)
    for cx in (650, 886):
        cy = 256
        hw, hh = 95, 70
        draw.rectangle([cx - hw - 8, cy - hh - 8, cx + hw + 8, cy + hh + 8], fill=(160, 165, 175, 255))
        draw.rectangle([cx - hw, cy - hh, cx + hw, cy + hh], fill=(235, 240, 250, 255))
        for lx in range(cx - hw + 10, cx + hw, 14):
            draw.line([(lx, cy - hh + 4), (lx, cy + hh - 4)], fill=(150, 155, 170, 255), width=2)
        draw.ellipse([cx - 28, cy - 28, cx + 28, cy + 28], fill=(255, 255, 255, 255), outline=(100, 140, 220, 255), width=4)
        draw.rectangle([cx + hw - 22, cy - hh + 4, cx + hw - 2, cy + hh - 4], fill=(245, 140, 10, 255))

    # Truck Heavy Dual Lamps (Scrap Hauler) -> (0, 512, 1024, 1024)
    draw.rectangle([10, 522, 1014, 1014], fill=(10, 11, 12, 255), outline=(45, 50, 58, 255), width=4)
    for cx in (240, 784):
        cy = 768
        hw, hh = 160, 110
        draw.rectangle([cx - hw - 14, cy - hh - 14, cx + hw + 14, cy + hh + 14], fill=(30, 32, 36, 255))
        draw.rectangle([cx - hw - 6, cy - hh - 6, cx + hw + 6, cy + hh + 6], fill=(140, 145, 155, 255))
        draw.rectangle([cx - hw, cy - hh, cx + hw, cy + hh], fill=(240, 245, 250, 255))
        for lx in range(cx - hw + 15, cx + hw, 20):
            draw.line([(lx, cy - hh + 5), (lx, cy + hh - 5)], fill=(160, 165, 180, 255), width=3)
        draw.rectangle([cx - hw, cy + hh + 20, cx + hw, cy + hh + 65], fill=(245, 140, 10, 255), outline=(180, 80, 0, 255), width=3)
        for lx in range(cx - hw + 10, cx + hw, 16):
            draw.line([(lx, cy + hh + 22), (lx, cy + hh + 63)], fill=(200, 100, 0, 255), width=2)

    # QUADRANT 2 (1024, 0, 2048, 1024): RADIATOR GRILLES
    # Horizontal Billet Grille with V8 Badge (Coupe) -> (1034, 10, 2038, 502)
    draw.rectangle([1034, 10, 2038, 502], fill=(8, 9, 10, 255), outline=(70, 75, 85, 255), width=4)
    for gy in range(35, 485, 20):
        draw.line([(1050, gy), (2020, gy)], fill=(130, 135, 145, 255), width=6)
        draw.line([(1050, gy + 3), (2020, gy + 3)], fill=(210, 215, 225, 255), width=2)
    draw.rectangle([1490, 210, 1582, 290], fill=(20, 20, 24, 255), outline=(220, 40, 30, 255), width=4)
    font_v8 = get_font(52)
    draw.text((1506, 222), "V8", font=font_v8, fill=(245, 245, 250, 255))

    # Heavy Expanded Diamond Steel Mesh (Scrap Hauler) -> (1034, 522, 2038, 1014)
    draw.rectangle([1034, 522, 2038, 1014], fill=(6, 7, 8, 255), outline=(50, 55, 65, 255), width=4)
    step_grid = 36
    for gx in range(1034, 2038, step_grid):
        draw.line([(gx, 522), (gx + 472, 1014)], fill=(110, 115, 125, 255), width=3)
        draw.line([(gx + 472, 522), (gx, 1014)], fill=(80, 85, 95, 255), width=3)
    for sx in (1260, 1536, 1812):
        draw.rectangle([sx - 16, 522, sx + 16, 1014], fill=(40, 42, 48, 255), outline=(130, 135, 145, 255), width=3)

    # QUADRANT 3 (0, 1024, 1024, 2048): TAILLIGHTS, STROBE LIGHTS & MARKERS
    # Horizontal LED Taillight Bar -> (10, 1034, 1014, 1480)
    draw.rectangle([10, 1034, 1014, 1480], fill=(15, 8, 8, 255), outline=(50, 40, 40, 255), width=4)
    draw.rectangle([40, 1070, 460, 1440], fill=(190, 15, 20, 255), outline=(240, 40, 45, 255), width=4)
    draw.rectangle([564, 1070, 984, 1440], fill=(190, 15, 20, 255), outline=(240, 40, 45, 255), width=4)
    for ry in range(1085, 1430, 20):
        draw.line([(45, ry), (455, ry)], fill=(240, 60, 65, 255), width=4)
        draw.line([(569, ry), (979, ry)], fill=(240, 60, 65, 255), width=4)
    draw.rectangle([476, 1200, 548, 1340], fill=(235, 240, 250, 255), outline=(180, 190, 210, 255), width=3)

    # Emergency Strobe Bar Lenses -> (10, 1500, 1014, 2038)
    draw.rectangle([10, 1500, 1014, 2038], fill=(12, 14, 18, 255), outline=(45, 50, 60, 255), width=4)
    # Blue Strobe (left)
    draw.rectangle([40, 1530, 460, 1990], fill=(10, 70, 210, 255), outline=(60, 130, 255, 255), width=6)
    for ly in range(1550, 1970, 22):
        draw.line([(45, ly), (455, ly)], fill=(70, 150, 255, 255), width=4)
    # Red Strobe (right)
    draw.rectangle([564, 1530, 984, 1990], fill=(210, 15, 25, 255), outline=(255, 60, 70, 255), width=6)
    for ly in range(1550, 1970, 22):
        draw.line([(569, ly), (979, ly)], fill=(255, 80, 90, 255), width=4)
    # Center Amber Warning Lens
    draw.rectangle([476, 1530, 548, 1750], fill=(240, 160, 15, 255), outline=(255, 200, 50, 255), width=3)
    # 5 Amber Cab Clearance Marker Lights (for Hauler Visor)
    for cly in range(1770, 1990, 44):
        draw.rectangle([482, cly, 542, cly + 32], fill=(255, 175, 10, 255), outline=(200, 120, 0, 255), width=3)
        draw.ellipse([495, cly + 6, 529, cly + 26], fill=(255, 240, 150, 255))

    # QUADRANT 4 (1024, 1024, 2048, 2048): LICENSE PLATES & BADGES
    # Plate: SCRAP-8 -> (1050, 1050, 1520, 1380)
    draw.rectangle([1050, 1050, 1520, 1380], fill=(225, 215, 185, 255), outline=(50, 45, 35, 255), width=8)
    draw.rectangle([1065, 1065, 1505, 1365], outline=(160, 140, 100, 255), width=3)
    font_plate_h = get_font(32)
    font_plate_main = get_font(84)
    font_sub = get_mono_font(24)
    draw.text((1140, 1080), "GEARS DISTRICT // SALVAGE", font=font_plate_h, fill=(80, 50, 20, 255))
    draw.text((1130, 1140), "SCRAP-8", font=font_plate_main, fill=(25, 20, 15, 255))
    draw.text((1125, 1305), "VOLATILE EXPIRATION 2026", font=font_sub, fill=(100, 60, 25, 255))

    # Plate: DZ-03 & HS-7 / FB-13 Municipal Plates -> (1550, 1050, 2030, 1380)
    draw.rectangle([1550, 1050, 2030, 1205], fill=(240, 195, 15, 255), outline=(20, 20, 20, 255), width=6)
    draw.rectangle([1562, 1062, 2018, 1193], outline=(180, 130, 0, 255), width=2)
    draw.text((1620, 1070), "BURNSIDE MUNICIPAL", font=get_font(26), fill=(20, 20, 20, 255))
    draw.text((1680, 1100), "DZ-03", font=get_font(68), fill=(15, 15, 15, 255))

    # Front Bullbar Plate: HS-7 / FB-13 (SCRAP MOVES THE CITY)
    draw.rectangle([1550, 1220, 2030, 1380], fill=(22, 24, 28, 255), outline=(240, 195, 15, 255), width=6)
    draw.text((1590, 1235), "HS-7 / FB-13", font=get_font(52), fill=(245, 200, 20, 255))
    draw.text((1600, 1310), "SCRAP MOVES THE CITY", font=get_mono_font(26), fill=(220, 225, 230, 255))

    # Plate: UNIT-09 -> (1050, 1430, 1520, 1760)
    draw.rectangle([1050, 1430, 1520, 1760], fill=(235, 240, 245, 255), outline=(10, 30, 80, 255), width=8)
    draw.rectangle([1065, 1445, 1505, 1745], outline=(80, 120, 200, 255), width=3)
    draw.text((1110, 1460), "CIVIC DEBT ENFORCEMENT", font=font_plate_h, fill=(10, 30, 90, 255))
    draw.text((1140, 1520), "UNIT-09", font=font_plate_main, fill=(10, 20, 50, 255))
    draw.text((1110, 1685), "PROTECT & INVOICE // 24/7", font=font_sub, fill=(15, 40, 110, 255))

    # Badges & Emblems -> (1550, 1430, 2030, 2030)
    draw.rectangle([1550, 1430, 2030, 2030], fill=(16, 18, 22, 255), outline=(45, 50, 60, 255), width=4)
    draw.polygon([(1790, 1470), (1890, 1530), (1850, 1650), (1790, 1720), (1730, 1650), (1690, 1530)], fill=(225, 180, 25, 255), outline=(255, 230, 120, 255))
    draw.polygon([(1790, 1490), (1870, 1540), (1835, 1635), (1790, 1695), (1745, 1635), (1710, 1540)], fill=(15, 35, 95, 255))
    font_badge = get_font(30)
    draw.text((1752, 1570), "CIVIC", font=font_badge, fill=(245, 200, 40, 255))
    for r_outer in range(80, 40, -10):
        draw.ellipse([1790 - r_outer, 1860 - r_outer, 1790 + r_outer, 1860 + r_outer], outline=(245, 140, 10, 255), width=4)
    draw.text((1730, 1835), "BURNSIDE", font=font_badge, fill=(245, 245, 250, 255))

    out_path = os.path.join(OUT_DIR, "tex_vehicle_trim.png")
    img.save(out_path)
    print("Saved Shared Vehicle Trim Sheet:", out_path)

# ==========================================
# 2. MUSCLE COUPE LIVERY (Discrete UV Atlas)
# ==========================================
def generate_coupe_livery():
    # Dark charcoal base matching reference's grimy weathered muscle body
    img = Image.new("RGBA", (2048, 2048), (28, 26, 24, 255))
    draw = ImageDraw.Draw(img)

    font_huge = get_font(220)   # Big "07" number panel
    font_title = get_font(95)
    font_sub = get_font(46)
    font_roof = get_font(260)

    # 1. RIGHT SIDE PROFILE (PIL Y: 0 to 480 -> V: 0.76 to 0.98)
    # UV: ny=0(REAR)=>PIL X LOW = REAR. "07" at HIGH X (front), "V8 SCRAP CHARGER" from LOW X.
    # Orange stripe band across mid-panel
    draw.rectangle([50, 240, 1998, 290], fill=(235, 85, 12, 255))  # Orange race stripe
    draw.rectangle([50, 295, 1998, 310], fill=(245, 165, 10, 255)) # Gold pinstripe
    # Large white "07" at front (HIGH PIL X)
    draw.text((1580, 40), "07", font=font_huge, fill=(255, 255, 255, 255))
    # "V8 SCRAP CHARGER" in orange
    draw.text((80, 70), "V8 SCRAP CHARGER", font=font_title, fill=(235, 85, 12, 255))
    draw.text((85, 175), "// NO REFUNDS //", font=font_sub, fill=(200, 200, 200, 255))
    # Burnside crown badge at far left (rear of car)
    draw.ellipse([60, 340, 120, 400], outline=(245, 165, 10, 255), width=4)
    draw.text((68, 352), "B", font=get_font(52), fill=(245, 165, 10, 255))

    # 2. LEFT SIDE PROFILE (PIL Y: 550 to 980 -> V: 0.52 to 0.74)
    # UV: (1-ny) => ny=0(REAR)=>PIL X HIGH = REAR. "07" at LOW X (front).
    draw.rectangle([50, 790, 1998, 840], fill=(235, 85, 12, 255))   # Orange race stripe
    draw.rectangle([50, 845, 1998, 860], fill=(245, 165, 10, 255))  # Gold pinstripe
    # Large white "07" at front (LOW PIL X)
    draw.text((60, 590), "07", font=font_huge, fill=(255, 255, 255, 255))
    # "V8 SCRAP CHARGER" in orange
    draw.text((380, 620), "V8 SCRAP CHARGER", font=font_title, fill=(235, 85, 12, 255))
    draw.text((385, 725), "// NO REFUNDS //", font=font_sub, fill=(200, 200, 200, 255))
    # Crown badge at far right (rear of car)
    draw.ellipse([1850, 890, 1910, 950], outline=(245, 165, 10, 255), width=4)
    draw.text((1858, 902), "B", font=get_font(52), fill=(245, 165, 10, 255))

    # 3. HOOD PANEL - orange racing stripes on dark
    draw.rectangle([300, 1060, 410, 1500], fill=(235, 85, 12, 255))   # Left orange stripe
    draw.rectangle([580, 1060, 690, 1500], fill=(235, 85, 12, 255))   # Right orange stripe
    draw.rectangle([350, 1060, 360, 1500], fill=(245, 165, 10, 255))  # Gold pinstripe
    draw.rectangle([630, 1060, 640, 1500], fill=(245, 165, 10, 255))  # Gold pinstripe

    # 4. ROOF PANEL - white "07" on dark with orange border
    draw.rectangle([1300, 1090, 1750, 1460], fill=(245, 245, 250, 255), outline=(235, 85, 12, 255), width=12)
    roof_txt_img = Image.new("RGBA", (400, 320), (0, 0, 0, 0))
    roof_txt_draw = ImageDraw.Draw(roof_txt_img)
    roof_txt_draw.text((20, 10), "07", font=font_roof, fill=(20, 20, 20, 255))
    roof_txt_rot = roof_txt_img.rotate(180)
    img.paste(roof_txt_rot, (1320, 1110), roof_txt_rot)

    # 5. TRUNK PANEL - dark with orange stripe
    draw.rectangle([300, 1560, 410, 1980], fill=(235, 85, 12, 255))  # Orange trunk stripe
    draw.rectangle([580, 1560, 690, 1980], fill=(235, 85, 12, 255))
    draw.text((750, 1700), "BURNSIDE", font=get_font(110), fill=(200, 200, 200, 255))

    # 6. CHIN SPOILER
    draw.rectangle([1050, 1680, 1980, 1850], fill=(28, 26, 24, 255), outline=(235, 85, 12, 255), width=6)
    draw.text((1080, 1730), "STEEL NOT STATUS  //  BURNSIDE DRIVES HARDER", font=get_font(38), fill=(235, 85, 12, 255))

    out_path = os.path.join(OUT_DIR, "tex_coupe_livery.png")
    img.save(out_path)
    print("Saved Muscle Coupe Livery (Discrete Atlas):", out_path)

# ==========================================
# 3. SCRAP HAULER LIVERY (Discrete UV Atlas)
# ==========================================
def generate_hauler_livery():
    img = Image.new("RGBA", (2048, 2048), (235, 175, 15, 255))
    draw = ImageDraw.Draw(img)

    font_huge = get_font(160)
    font_title = get_font(105)
    font_sub = get_font(52)
    font_mono = get_mono_font(36)

    # 1. BED RIGHT SIDE (PIL Y: 50 to 520 -> V: 0.75 to 0.98)
    draw_chevrons(draw, 50, 390, 1998, 490, width=32, col1=(245, 190, 10, 255), col2=(20, 20, 20, 255))
    draw.text((120, 140), "BURNSIDE SCRAP HAULAGE", font=font_title, fill=(20, 20, 20, 255))
    draw.text((125, 260), "// SALVAGE DIVISION DZ-03 // VOLATILE LOGISTICS", font=font_sub, fill=(210, 30, 20, 255))
    draw.rectangle([1650, 120, 1940, 350], fill=(20, 20, 20, 255), outline=(245, 190, 10, 255), width=8)
    draw.text((1710, 150), "03", font=font_huge, fill=(245, 190, 10, 255))

    # 2. BED LEFT SIDE (PIL Y: 580 to 1050 -> V: 0.49 to 0.72)
    draw_chevrons(draw, 50, 920, 1998, 1020, width=32, col1=(245, 190, 10, 255), col2=(20, 20, 20, 255))
    draw.text((120, 670), "BURNSIDE SCRAP HAULAGE", font=font_title, fill=(20, 20, 20, 255))
    draw.text((125, 790), "// SALVAGE DIVISION DZ-03 // VOLATILE LOGISTICS", font=font_sub, fill=(210, 30, 20, 255))
    draw.rectangle([1650, 650, 1940, 880], fill=(20, 20, 20, 255), outline=(245, 190, 10, 255), width=8)
    draw.text((1710, 680), "03", font=font_huge, fill=(245, 190, 10, 255))

    # 3. CAB DOORS LEFT (PIL X: 50 to 1000, Y: 1100 to 1550 -> U: 0.02 to 0.49, V: 0.24 to 0.46)
    draw.rectangle([80, 1150, 320, 1450], fill=(20, 20, 20, 255), outline=(245, 190, 10, 255), width=8)
    draw.text((120, 1200), "03", font=font_huge, fill=(245, 190, 10, 255))
    draw.text((360, 1180), "BURNSIDE HEAVY DIVISION", font=get_font(60), fill=(20, 20, 20, 255))
    draw.text((365, 1270), "TARE: 14,200 KG // MAX: 38,000 KG", font=font_mono, fill=(20, 20, 20, 255))

    # 4. CAB DOORS RIGHT (PIL X: 1050 to 2000, Y: 1100 to 1550 -> U: 0.51 to 0.98, V: 0.24 to 0.46)
    draw.rectangle([1080, 1150, 1320, 1450], fill=(20, 20, 20, 255), outline=(245, 190, 10, 255), width=8)
    draw.text((1120, 1200), "03", font=font_huge, fill=(245, 190, 10, 255))
    draw.text((1360, 1180), "BURNSIDE HEAVY DIVISION", font=get_font(60), fill=(20, 20, 20, 255))
    draw.text((1365, 1270), "TARE: 14,200 KG // MAX: 38,000 KG", font=font_mono, fill=(20, 20, 20, 255))

    # 5. SUN VISOR (PIL X: 50 to 1000, Y: 1600 to 1980 -> U: 0.02 to 0.49, V: 0.03 to 0.22)
    draw.rectangle([50, 1650, 1000, 1950], fill=(20, 20, 20, 255))
    draw.text((220, 1720), "BURNSIDE", font=get_font(120), fill=(245, 190, 10, 255))

    # 6. TAILGATE (PIL X: 1050 to 2000, Y: 1600 to 1980 -> U: 0.51 to 0.98, V: 0.03 to 0.22)
    draw_chevrons(draw, 1050, 1620, 2000, 1760, width=32, col1=(245, 190, 10, 255), col2=(20, 20, 20, 255))
    draw.rectangle([1080, 1780, 1970, 1960], fill=(210, 25, 20, 255), outline=(255, 255, 255, 255), width=6)
    draw.text((1120, 1820), "STAND CLEAR // VOLATILE RECOVERY", font=get_font(62), fill=(255, 255, 255, 255))

    out_path = os.path.join(OUT_DIR, "tex_hauler_livery.png")
    img.save(out_path)
    print("Saved Scrap Hauler Livery (Discrete Atlas):", out_path)

# ==========================================
# 4. SECURITY INTERCEPTOR LIVERY (Discrete UV Atlas)
# ==========================================
def generate_interceptor_livery():
    img = Image.new("RGBA", (2048, 2048), (26, 28, 34, 255))
    draw = ImageDraw.Draw(img)

    font_huge = get_font(180)
    font_title = get_font(96)
    font_sub = get_font(52)
    font_mono = get_mono_font(36)
    font_roof = get_font(280)

    # 1. RIGHT SIDE PROFILE (PIL Y: 0 to 530 -> V: 0.75 to 0.98)
    # UV swapped: ny direct => ny=0(REAR)=>u=u1_r(low)=>PIL X LOW = REAR
    # Draw text at left (rear), "09" at right (front)
    draw.rectangle([50, 80, 1950, 480], fill=(245, 245, 250, 255), outline=(15, 20, 30, 255), width=6)
    draw.text((60, 130), "CIVIC DEBT ENFORCEMENT", font=font_title, fill=(10, 25, 75, 255))
    draw.text((65, 240), "// PROTECT & INVOICE // 24/7 PATROL", font=font_sub, fill=(200, 30, 20, 255))
    draw.text((65, 310), "FAILURE TO COMPLY ACCRUES 12% HOURLY", font=font_mono, fill=(50, 55, 65, 255))
    draw_chevrons(draw, 60, 370, 500, 440, width=20, col1=(240, 180, 15, 255), col2=(20, 20, 25, 255))
    draw.text((1600, 130), "09", font=font_huge, fill=(10, 25, 75, 255))

    # 2. LEFT SIDE PROFILE (PIL Y: 520 to 1050 -> V: 0.49 to 0.72)
    # UV swapped: (1-ny) => ny=0(REAR)=>u=u2_l(high)=>PIL X HIGH = REAR
    # "09" at LEFT (front of car), livery text to right
    draw.rectangle([50, 600, 1950, 1000], fill=(245, 245, 250, 255), outline=(15, 20, 30, 255), width=6)
    draw.text((60, 650), "09", font=font_huge, fill=(10, 25, 75, 255))
    draw.text((280, 660), "CIVIC DEBT ENFORCEMENT", font=font_title, fill=(10, 25, 75, 255))
    draw.text((285, 770), "// PROTECT & INVOICE // 24/7 PATROL", font=font_sub, fill=(200, 30, 20, 255))
    draw.text((285, 840), "FAILURE TO COMPLY ACCRUES 12% HOURLY", font=font_mono, fill=(50, 55, 65, 255))
    draw_chevrons(draw, 1400, 710, 1900, 870, width=20, col1=(240, 180, 15, 255), col2=(20, 20, 25, 255))
    draw.text((1440, 885), "DEBT MONITORED", font=font_sub, fill=(240, 180, 15, 255))

    # 3. HOOD PANEL (PIL X: 100 to 950, Y: 1100 to 1550 -> U: 0.05 to 0.46, V: 0.24 to 0.46)
    draw.polygon([(200, 1150), (850, 1150), (525, 1500)], fill=(245, 245, 250, 255), outline=(15, 20, 30, 255))
    draw.text((430, 1220), "UNIT-09", font=get_font(84), fill=(15, 20, 30, 255))

    # 4. ROOF PANEL (PIL X: 1050 to 1950, Y: 1100 to 1550 -> U: 0.51 to 0.95, V: 0.24 to 0.46)
    draw.rectangle([1100, 1120, 1900, 1520], fill=(245, 245, 250, 255), outline=(15, 20, 30, 255), width=10)
    draw.text((1380, 1150), "09", font=font_roof, fill=(15, 20, 30, 255))
    draw.text((1240, 1420), "MUNICIPAL PURSUIT", font=get_font(68), fill=(10, 25, 75, 255))

    # 5. TRUNK PANEL (PIL X: 100 to 1950, Y: 1620 to 1980 -> U: 0.05 to 0.95, V: 0.03 to 0.21)
    draw.rectangle([200, 1680, 1848, 1920], fill=(15, 20, 30, 255), outline=(240, 180, 15, 255), width=6)
    draw.text((380, 1750), "STAY IN COMPLIANCE  //  QUOTA ENFORCER", font=get_font(72), fill=(245, 245, 250, 255))

    out_path = os.path.join(OUT_DIR, "tex_security_interceptor_livery.png")
    img.save(out_path)
    print("Saved Security Interceptor Livery (Discrete Atlas):", out_path)

if __name__ == "__main__":
    generate_trim_sheet()
    generate_coupe_livery()
    generate_hauler_livery()
    generate_interceptor_livery()
    print("ALL VEHICLE MODULAR TEXTURES GENERATED SUCCESSFULLY.")
