#!/usr/bin/env python3
import os
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

random.seed(42)
OUT_DIR = "godot/textures/urban_clutter"
os.makedirs(OUT_DIR, exist_ok=True)

def get_font(size):
    font_paths = [
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/SFNSMono.ttf",
        "/System/Library/Fonts/Geneva.ttf",
        "/Library/Fonts/Arial.ttf"
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                pass
    return ImageFont.load_default()

def make_vending_machine_texture():
    w, h = 1024, 1024
    # Base dark industrial teal-gray casing
    im = Image.new("RGB", (w, h), (42, 48, 54))
    draw = ImageDraw.Draw(im)

    # 1. Main cabinet side/top panels (0, 0, 512, 512)
    for y in range(0, 512):
        for x in range(0, 512):
            noise = random.randint(-8, 8)
            r = max(0, min(255, 38 + noise))
            g = max(0, min(255, 45 + noise))
            b = max(0, min(255, 52 + noise))
            im.putpixel((x, y), (r, g, b))

    # Add rust / scratches to side panel
    for _ in range(12):
        lx = random.randint(20, 480)
        ly = random.randint(20, 480)
        draw.line([(lx, ly), (lx + random.randint(-40, 40), ly + random.randint(10, 60))], fill=(75, 50, 35), width=2)

    # 2. Illuminated Top Marquee: "NEO-COLA // RECLAIMED REFRESH" (512, 0, 1024, 256)
    draw.rectangle([514, 2, 1022, 254], fill=(16, 22, 28))
    draw.rectangle([520, 10, 1016, 246], fill=(24, 85, 110))
    # Cyan gradient bars
    for i in range(10):
        c_val = 110 + i * 12
        draw.rectangle([530, 20 + i*6, 1006, 24 + i*6], fill=(30, c_val, c_val + 20))

    font_large = get_font(42)
    font_med = get_font(20)
    font_small = get_font(14)

    draw.text((540, 90), "NEO-COLA", font=font_large, fill=(230, 255, 255))
    draw.text((545, 145), "CONTRABAND DISPENSER // 0.84 MHz", font=font_med, fill=(255, 200, 40))
    draw.text((545, 185), "AUTHORIZED GEARS CITIZENS ONLY", font=font_small, fill=(180, 220, 230))

    # Hazard stripe band on marquee bottom
    stripe_w = 24
    for sx in range(514, 1024, stripe_w * 2):
        draw.polygon([(sx, 220), (sx + stripe_w, 220), (sx + stripe_w - 12, 250), (sx - 12, 250)], fill=(240, 180, 20))
        draw.polygon([(sx + stripe_w, 220), (sx + stripe_w*2, 220), (sx + stripe_w*2 - 12, 250), (sx + stripe_w - 12, 250)], fill=(20, 20, 22))

    # 3. Front Window Display / Cans & Cartridges Grid (0, 512, 512, 1024)
    draw.rectangle([2, 514, 510, 1022], fill=(18, 26, 32))
    # Shelves
    for sy in [620, 730, 840, 950]:
        draw.rectangle([10, sy, 502, sy + 14], fill=(70, 78, 85))
        draw.line([(10, sy + 14), (502, sy + 14)], fill=(120, 130, 140), width=2)
        # Contraband cans / fuel cells on shelf
        for cx in range(30, 480, 75):
            color_can = random.choice([
                (200, 40, 40),   # Red Nitro Can
                (30, 160, 220),  # Cyan Coolant
                (220, 180, 20),  # Amber Fuel Cell
                (50, 190, 70),   # Green Catalyst
                (160, 50, 210)   # Violet Distillate
            ])
            # Draw can / battery cylinder
            draw.rectangle([cx, sy - 70, cx + 50, sy], fill=color_can)
            draw.rectangle([cx + 5, sy - 65, cx + 45, sy - 5], fill=(max(0, color_can[0]-30), max(0, color_can[1]-30), max(0, color_can[2]-30)))
            draw.ellipse([cx + 5, sy - 75, cx + 45, sy - 65], fill=(200, 200, 210))
            draw.text((cx + 10, sy - 45), "FB", font=font_small, fill=(255, 255, 255))

    # 4. Right-side Control Panel & Keypad (512, 256, 768, 1024)
    draw.rectangle([514, 258, 766, 1022], fill=(32, 36, 40))
    # Digital Status Display
    draw.rectangle([530, 280, 750, 400], fill=(8, 16, 20))
    draw.rectangle([536, 286, 744, 394], fill=(12, 38, 44))
    draw.text((545, 300), "STATUS: ONLINE", font=font_med, fill=(50, 240, 120))
    draw.text((545, 335), "FREQ: 0.840 MHz", font=font_med, fill=(40, 200, 255))
    draw.text((545, 370), "READY FOR TAP [E]", font=font_small, fill=(240, 220, 40))

    # Keypad buttons
    for r in range(4):
        for c in range(3):
            bx = 550 + c * 65
            by = 430 + r * 55
            draw.rectangle([bx, by, bx + 50, by + 42], fill=(60, 68, 74))
            draw.rectangle([bx + 2, by + 2, bx + 48, by + 40], fill=(78, 88, 96))
            num_char = str(r * 3 + c + 1) if (r * 3 + c + 1) <= 9 else ("*" if c==0 else ("0" if c==1 else "#"))
            draw.text((bx + 18, by + 10), num_char, font=font_med, fill=(220, 230, 240))

    # Card / Biometric Scanner Slot
    draw.rectangle([545, 680, 735, 710], fill=(15, 15, 18))
    draw.rectangle([550, 692, 730, 698], fill=(5, 5, 6))
    draw.text((550, 660), "INSERT CRED CARD // TAP", font=font_small, fill=(180, 190, 200))

    # Currency Bill Validator Slot
    draw.rectangle([545, 750, 735, 780], fill=(15, 15, 18))
    draw.rectangle([550, 762, 730, 768], fill=(30, 220, 80))
    draw.text((550, 730), "CURRENCY / SCRAP CHITS", font=font_small, fill=(180, 190, 200))

    # Speaker Grille Louvers
    for gy in range(830, 980, 14):
        draw.rectangle([550, gy, 730, gy + 6], fill=(18, 20, 24))

    # 5. Bottom Dispenser Hopper & Flap (768, 256, 1024, 768)
    draw.rectangle([770, 258, 1022, 766], fill=(26, 30, 34))
    # Recessed Flap Door
    draw.rectangle([790, 300, 1000, 560], fill=(12, 14, 16))
    draw.rectangle([800, 310, 990, 550], fill=(55, 62, 70))
    # Chrome Handle Bar
    draw.rectangle([820, 410, 970, 435], fill=(180, 190, 200))
    draw.rectangle([822, 412, 968, 433], fill=(220, 230, 240))
    draw.text((845, 470), "PUSH FOR GOODS", font=font_med, fill=(200, 210, 220))
    draw.text((850, 510), "HEAVY STEEL REINFORCED", font=font_small, fill=(140, 150, 160))

    # 6. Ventilation Louvers / Rear Access (768, 768, 1024, 1024)
    draw.rectangle([770, 770, 1022, 1022], fill=(36, 40, 45))
    for vy in range(785, 1010, 16):
        draw.rectangle([785, vy, 1005, vy + 8], fill=(16, 18, 20))
        draw.line([(785, vy), (1005, vy)], fill=(60, 68, 75), width=1)

    out_path = os.path.join(OUT_DIR, "tex_vending_machine.png")
    im.save(out_path)
    print("Successfully generated:", out_path)

if __name__ == "__main__":
    make_vending_machine_texture()
