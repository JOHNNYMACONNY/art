import os
import math
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

random.seed(42)
OUT_DIR = "godot/textures/urban_clutter"
os.makedirs(OUT_DIR, exist_ok=True)

def get_font(size, bold=False):
    font_paths = [
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Geneva.ttf",
        "/System/Library/Fonts/SFNSMono.ttf",
        "/Library/Fonts/Arial.ttf"
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                pass
    return ImageFont.load_default()

# 1. tex_asphalt.png (512x512) - Medium-dark urban asphalt with strong wear contrast
def make_asphalt():
    w, h = 512, 512
    im = Image.new("RGB", (w, h), (82, 85, 90))
    pixels = im.load()
    for y in range(h):
        for x in range(w):
            v = random.randint(-16, 16)
            r = max(0, min(255, 82 + v))
            g = max(0, min(255, 85 + v))
            b = max(0, min(255, 90 + v))
            pixels[x, y] = (r, g, b)
            
    # Aggregate white/sand specks
    for _ in range(1200):
        x = random.randint(0, w-1)
        y = random.randint(0, h-1)
        c = random.randint(140, 190)
        pixels[x, y] = (c, c, c)
        
    track_overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    t_draw = ImageDraw.Draw(track_overlay)
    # Heavy tire scrub lanes (vertical)
    for y in range(0, h, 2):
        t_draw.line([(100 + random.randint(-10, 10), y), (190 + random.randint(-10, 10), y)], fill=(38, 40, 44, 95), width=3)
        t_draw.line([(320 + random.randint(-10, 10), y), (410 + random.randint(-10, 10), y)], fill=(38, 40, 44, 95), width=3)
        
    # Large oil puddle drops and drips
    for _ in range(18):
        ox = random.randint(200, 310)
        oy = random.randint(30, 480)
        rad_x = random.randint(18, 45)
        rad_y = random.randint(25, 75)
        t_draw.ellipse([ox - rad_x, oy - rad_y, ox + rad_x, oy + rad_y], fill=(22, 22, 24, random.randint(140, 210)))

    # Asphalt cracks
    for _ in range(6):
        cx = random.randint(40, 460)
        cy = random.randint(40, 460)
        points = [(cx, cy)]
        for _ in range(10):
            cx += random.randint(-22, 22)
            cy += random.randint(-22, 22)
            points.append((cx, cy))
        t_draw.line(points, fill=(35, 36, 40, 220), width=2)

    im.paste(Image.alpha_composite(Image.new("RGBA", (w, h), (0,0,0,0)), track_overlay).convert("RGB"), (0,0), track_overlay)
    im = im.filter(ImageFilter.SMOOTH_MORE)
    im.save(os.path.join(OUT_DIR, "tex_asphalt.png"))
    print("Created tex_asphalt.png")

# 2. tex_sidewalk.png (512x512) - Flagstone paver slabs with grime and weeds
def make_sidewalk():
    w, h = 512, 512
    im = Image.new("RGB", (w, h), (160, 155, 146))
    draw = ImageDraw.Draw(im)
    
    paver_size = 128
    for row in range(4):
        for col in range(4):
            x0 = col * paver_size
            y0 = row * paver_size
            x1 = x0 + paver_size
            y1 = y0 + paver_size
            
            base_shift = random.randint(-20, 20)
            slab_col = (
                max(0, min(255, 162 + base_shift)),
                max(0, min(255, 156 + base_shift)),
                max(0, min(255, 148 + base_shift))
            )
            draw.rectangle([x0+3, y0+3, x1-3, y1-3], fill=slab_col)
            
            # Aggregate speckles
            for _ in range(120):
                px = random.randint(x0+4, x1-4)
                py = random.randint(y0+4, y1-4)
                sc = random.randint(-25, 25)
                draw.point((px, py), fill=(
                    max(0, min(255, slab_col[0] + sc)),
                    max(0, min(255, slab_col[1] + sc)),
                    max(0, min(255, slab_col[2] + sc))
                ))
                
            # Deep beveled joints
            draw.rectangle([x0, y0, x1, y0+4], fill=(55, 52, 48))
            draw.rectangle([x0, y0, x0+4, y1], fill=(55, 52, 48))
            draw.rectangle([x0, y1-4, x1, y1], fill=(85, 82, 76))
            draw.rectangle([x1-4, y0, x1, y1], fill=(85, 82, 76))
            
    # Moss & weed sprouts in joints
    for _ in range(40):
        gx = random.choice([0, 128, 256, 384, 511]) + random.randint(-6, 6)
        gy = random.choice([0, 128, 256, 384, 511]) + random.randint(-6, 6)
        draw.ellipse([gx-7, gy-7, gx+7, gy+7], fill=(48, 62, 42)) # Green moss
        draw.ellipse([gx-4, gy-4, gx+4, gy+4], fill=(32, 42, 28))
        
    # Dark gum wads and cigarette soot
    for _ in range(20):
        gx = random.randint(15, w-15)
        gy = random.randint(15, h-15)
        draw.ellipse([gx-4, gy-4, gx+4, gy+4], fill=(38, 38, 40))
        
    # Curbside grime accumulation on right side
    grime = Image.new("RGBA", (w, h), (0,0,0,0))
    g_draw = ImageDraw.Draw(grime)
    for x in range(w-80, w):
        alpha = int(((x - (w-80)) / 80.0) * 110)
        g_draw.line([(x, 0), (x, h)], fill=(40, 38, 35, alpha))
    im.paste(Image.alpha_composite(Image.new("RGBA", (w, h), (0,0,0,0)), grime).convert("RGB"), (0,0), grime)

    im.save(os.path.join(OUT_DIR, "tex_sidewalk.png"))
    print("Created tex_sidewalk.png")

# 3. tex_brick_wall.png (512x512) - Terracotta running bond with mortar and soot
def make_brick():
    w, h = 512, 512
    im = Image.new("RGB", (w, h), (68, 62, 58)) # Mortar base
    draw = ImageDraw.Draw(im)
    
    brick_h = 32
    brick_w = 64
    rows = h // brick_h
    
    for r in range(rows):
        y0 = r * brick_h
        y1 = y0 + brick_h - 4
        x_offset = (r % 2) * (brick_w // 2)
        cols = (w // brick_w) + 2
        for c in range(-1, cols):
            x0 = c * brick_w + x_offset
            x1 = x0 + brick_w - 4
            
            bx0 = max(0, x0)
            by0 = max(0, y0)
            bx1 = min(w-1, x1)
            by1 = min(h-1, y1)
            
            if bx1 <= bx0 or by1 <= by0:
                continue
                
            r_col = random.randint(130, 185)
            g_col = random.randint(58, 88)
            b_col = random.randint(45, 68)
            
            draw.rectangle([bx0, by0, bx1, by1], fill=(r_col, g_col, b_col))
            
            for _ in range(18):
                bx = random.randint(bx0, bx1)
                by = random.randint(by0, by1)
                draw.point((bx, by), fill=(r_col - 24, g_col - 12, b_col - 12))

    # Soot & rain stains
    streak_overlay = Image.new("RGBA", (w, h), (0,0,0,0))
    s_draw = ImageDraw.Draw(streak_overlay)
    for _ in range(16):
        sx = random.randint(10, w-10)
        s_len = random.randint(80, 360)
        s_draw.line([(sx, 0), (sx + random.randint(-6, 6), s_len)], fill=(18, 16, 14, random.randint(70, 140)), width=random.randint(6, 18))
    im.paste(Image.alpha_composite(Image.new("RGBA", (w, h), (0,0,0,0)), streak_overlay).convert("RGB"), (0,0), streak_overlay)
    
    im.save(os.path.join(OUT_DIR, "tex_brick_wall.png"))
    print("Created tex_brick_wall.png")

# 4. tex_cardboard.png (512x512)
def make_cardboard():
    w, h = 512, 512
    im = Image.new("RGB", (w, h), (175, 132, 90))
    draw = ImageDraw.Draw(im)
    
    for y in range(0, h, 2):
        c_shift = random.randint(-10, 10)
        draw.line([(0, y), (w, y)], fill=(175 + c_shift, 132 + c_shift, 90 + c_shift))
        
    tape_col = (205, 172, 118)
    tape_border = (145, 110, 65)
    draw.rectangle([0, 215, w, 298], fill=tape_col)
    draw.line([(0, 215), (w, 215)], fill=tape_border, width=2)
    draw.line([(0, 298), (w, 298)], fill=tape_border, width=2)
    
    font_large = get_font(38, bold=True)
    font_med = get_font(22, bold=True)
    font_small = get_font(14)
    
    draw.text((60, 55), "FRAGILE", fill=(30, 25, 20), font=font_large)
    draw.text((60, 105), "HANDLE WITH CARE", fill=(40, 35, 30), font=font_med)
    
    draw.rectangle([380, 50, 400, 115], fill=(30, 25, 20))
    draw.polygon([(365, 70), (390, 35), (415, 70)], fill=(30, 25, 20))
    draw.rectangle([430, 50, 450, 115], fill=(30, 25, 20))
    draw.polygon([(415, 70), (440, 35), (465, 70)], fill=(30, 25, 20))
    draw.text((375, 125), "THIS SIDE UP", fill=(30, 25, 20), font=font_small)

    label_x, label_y = 55, 330
    draw.rectangle([label_x, label_y, label_x + 230, label_y + 145], fill=(242, 240, 232))
    draw.rectangle([label_x, label_y, label_x + 230, label_y + 145], outline=(120, 115, 105), width=2)
    
    draw.text((label_x + 12, label_y + 10), "PRIORITY FREIGHT // GEARS", fill=(15, 15, 15), font=font_small)
    draw.text((label_x + 12, label_y + 28), "DEST: SUM YUNG GAI MOTORS", fill=(15, 15, 15), font=font_small)
    
    bx = label_x + 18
    by = label_y + 50
    for _ in range(30):
        bw = random.choice([2, 3, 5, 7])
        draw.rectangle([bx, by, bx + bw, by + 55], fill=(15, 15, 15))
        bx += bw + random.choice([2, 4])
        if bx > label_x + 210:
            break
    draw.text((label_x + 35, label_y + 115), "*8842-GEARS-99*", fill=(15, 15, 15), font=font_small)

    gx, gy = 360, 350
    draw.ellipse([gx, gy, gx + 45, gy + 32], fill=(30, 25, 20))
    draw.rectangle([gx + 20, gy + 32, gx + 25, gy + 68], fill=(30, 25, 20))
    draw.rectangle([gx + 10, gy + 68, gx + 35, gy + 74], fill=(30, 25, 20))

    im.save(os.path.join(OUT_DIR, "tex_cardboard.png"))
    print("Created tex_cardboard.png")

# 5. tex_newspaper_bin_blue.png (512x512)
def make_blue_bin():
    w, h = 512, 512
    im = Image.new("RGB", (w, h), (38, 76, 138))
    draw = ImageDraw.Draw(im)
    
    draw.rectangle([12, 12, w-12, h-12], outline=(18, 42, 85), width=8)
    draw.rectangle([18, 18, w-18, h-18], outline=(80, 130, 205), width=4)
    
    win_x0, win_y0, win_x1, win_y1 = 40, 100, w-40, 340
    draw.rectangle([win_x0, win_y0, win_x1, win_y1], fill=(235, 232, 222))
    draw.rectangle([win_x0, win_y0, win_x1, win_y1], outline=(15, 20, 28), width=10)
    
    font_mast = get_font(30, bold=True)
    font_sub = get_font(15, bold=True)
    font_head = get_font(24, bold=True)
    font_tiny = get_font(11)
    
    draw.text((win_x0 + 28, win_y0 + 12), "THE LIBERTY TREE", fill=(15, 15, 15), font=font_mast)
    draw.line([(win_x0 + 12, win_y0 + 48), (win_x1 - 12, win_y0 + 48)], fill=(15, 15, 15), width=3)
    draw.text((win_x0 + 15, win_y0 + 52), "LIBERTY CITY'S LEADING DAILY  •  PRICE 25 CENTS", fill=(45, 45, 45), font=font_tiny)
    draw.line([(win_x0 + 12, win_y0 + 68), (win_x1 - 12, win_y0 + 68)], fill=(15, 15, 15), width=2)
    
    draw.text((win_x0 + 12, win_y0 + 74), "MAYOR PROCLAIMS CRISIS", fill=(15, 15, 15), font=font_head)
    draw.text((win_x0 + 12, win_y0 + 102), "POLICE CRACKDOWN IN GEARS DISTRICT", fill=(25, 25, 25), font=font_sub)
    
    draw.rectangle([win_x0 + 12, win_y0 + 128, win_x0 + 185, win_y1 - 15], fill=(95, 100, 105))
    draw.rectangle([win_x0 + 12, win_y0 + 128, win_x0 + 185, win_y1 - 15], outline=(30, 30, 30), width=2)
    
    col_x = win_x0 + 200
    for ly in range(win_y0 + 128, win_y1 - 15, 8):
        draw.line([(col_x, ly), (win_x1 - 18, ly)], fill=(65, 65, 65), width=4)
        
    glass_overlay = Image.new("RGBA", (w, h), (0,0,0,0))
    g_draw = ImageDraw.Draw(glass_overlay)
    g_draw.polygon([(win_x0, win_y0), (win_x0 + 110, win_y0), (win_x1, win_y1 - 110), (win_x1, win_y1)], fill=(255, 255, 255, 65))
    im.paste(Image.alpha_composite(Image.new("RGBA", (w, h), (0,0,0,0)), glass_overlay).convert("RGB"), (0,0), glass_overlay)
    
    draw.rectangle([65, 30, w-65, 90], fill=(28, 32, 38))
    draw.rectangle([65, 30, w-65, 90], outline=(190, 195, 205), width=3)
    draw.text((95, 38), "INSERT 25¢  •  PULL HANDLE", fill=(240, 240, 240), font=font_sub)
    draw.rectangle([w//2 - 65, 65, w//2 + 65, 76], fill=(8, 8, 10))
    
    draw.rectangle([90, 375, w-90, 445], fill=(22, 48, 92))
    draw.rectangle([90, 375, w-90, 445], outline=(12, 25, 50), width=4)
    draw.rectangle([w//2 - 100, 398, w//2 + 100, 420], fill=(205, 210, 220))
    draw.rectangle([w//2 - 100, 398, w//2 + 100, 420], outline=(75, 80, 90), width=3)

    im.save(os.path.join(OUT_DIR, "tex_newspaper_bin_blue.png"))
    print("Created tex_newspaper_bin_blue.png")

# 6. tex_newspaper_bin_amber.png (512x512)
def make_amber_bin():
    w, h = 512, 512
    im = Image.new("RGB", (w, h), (225, 155, 25))
    draw = ImageDraw.Draw(im)
    
    draw.rectangle([12, 12, w-12, h-12], outline=(145, 90, 12), width=8)
    draw.rectangle([18, 18, w-18, h-18], outline=(255, 205, 85), width=4)
    
    win_x0, win_y0, win_x1, win_y1 = 40, 100, w-40, 340
    draw.rectangle([win_x0, win_y0, win_x1, win_y1], fill=(235, 230, 218))
    draw.rectangle([win_x0, win_y0, win_x1, win_y1], outline=(15, 15, 15), width=10)
    
    font_mast = get_font(32, bold=True)
    font_sub = get_font(15, bold=True)
    font_head = get_font(24, bold=True)
    font_tiny = get_font(11)
    
    draw.text((win_x0 + 38, win_y0 + 10), "DAILY GLOBE", fill=(190, 18, 18), font=font_mast)
    draw.line([(win_x0 + 12, win_y0 + 48), (win_x1 - 12, win_y0 + 48)], fill=(15, 15, 15), width=3)
    draw.text((win_x0 + 20, win_y0 + 52), "THE METROPOLIS MORNING POST  •  50 CENTS", fill=(45, 45, 45), font=font_tiny)
    draw.line([(win_x0 + 12, win_y0 + 68), (win_x1 - 12, win_y0 + 68)], fill=(15, 15, 15), width=2)
    
    draw.text((win_x0 + 12, win_y0 + 74), "GANG WAR EXPLODES", fill=(15, 15, 15), font=font_head)
    draw.text((win_x0 + 12, win_y0 + 102), "TRIADS TAKE OVER GEARS SCRAP", fill=(25, 25, 25), font=font_sub)
    
    draw.rectangle([win_x0 + 12, win_y0 + 128, win_x0 + 185, win_y1 - 15], fill=(80, 85, 90))
    draw.rectangle([win_x0 + 12, win_y0 + 128, win_x0 + 185, win_y1 - 15], outline=(25, 25, 25), width=2)
    
    col_x = win_x0 + 200
    for ly in range(win_y0 + 128, win_y1 - 15, 8):
        draw.line([(col_x, ly), (win_x1 - 18, ly)], fill=(60, 60, 60), width=4)
        
    glass_overlay = Image.new("RGBA", (w, h), (0,0,0,0))
    g_draw = ImageDraw.Draw(glass_overlay)
    g_draw.polygon([(win_x0, win_y0), (win_x0 + 110, win_y0), (win_x1, win_y1 - 110), (win_x1, win_y1)], fill=(255, 255, 255, 65))
    im.paste(Image.alpha_composite(Image.new("RGBA", (w, h), (0,0,0,0)), glass_overlay).convert("RGB"), (0,0), glass_overlay)
    
    draw.rectangle([65, 30, w-65, 90], fill=(32, 32, 36))
    draw.rectangle([65, 30, w-65, 90], outline=(185, 190, 200), width=3)
    draw.text((100, 38), "EXACT CHANGE ONLY  •  50¢", fill=(245, 245, 245), font=font_sub)
    draw.rectangle([w//2 - 65, 65, w//2 + 65, 76], fill=(8, 8, 10))
    
    draw.rectangle([90, 375, w-90, 445], fill=(168, 108, 16))
    draw.rectangle([90, 375, w-90, 445], outline=(95, 60, 10), width=4)
    draw.rectangle([w//2 - 100, 398, w//2 + 100, 420], fill=(205, 210, 220))
    draw.rectangle([w//2 - 100, 398, w//2 + 100, 420], outline=(80, 85, 95), width=3)

    im.save(os.path.join(OUT_DIR, "tex_newspaper_bin_amber.png"))
    print("Created tex_newspaper_bin_amber.png")

# 7. tex_storefront_fascia.png (512x128) - Giant Chinatown Wars SUM YUNG GAI
def make_storefront_fascia():
    w, h = 512, 128
    im = Image.new("RGB", (w, h), (20, 75, 85))
    draw = ImageDraw.Draw(im)
    
    draw.rectangle([2, 2, w-3, h-3], outline=(220, 55, 40), width=6)
    draw.rectangle([8, 8, w-9, h-9], outline=(255, 205, 30), width=3)
    
    font_giant = get_font(72, bold=True)
    font_sub = get_font(20, bold=True)
    
    text = "SUM YUNG GAI"
    for ox, oy in [(-3, -3), (3, -3), (-3, 3), (3, 3), (0, 4), (4, 0)]:
        draw.text((25 + ox, 12 + oy), text, fill=(180, 25, 20), font=font_giant)
    draw.text((25, 12), text, fill=(255, 225, 45), font=font_giant)
    draw.text((38, 92), "★ CHOP SHOP // AUTO REPAIR // 24 HRS ★", fill=(255, 255, 255), font=font_sub)

    im.save(os.path.join(OUT_DIR, "tex_storefront_fascia.png"))
    print("Created tex_storefront_fascia.png")

# 8. tex_window_display.png (512x512) - Giant neon heart & OPEN 24H
def make_window_display():
    w, h = 512, 512
    im = Image.new("RGB", (w, h), (18, 22, 28))
    draw = ImageDraw.Draw(im)

    for y in range(h):
        fac = (y / float(h))
        col = (int(45 + fac * 85), int(32 + fac * 55), int(24 + fac * 30))
        draw.line([(0, y), (w, y)], fill=col)

    draw.rectangle([0, 0, w, 12], fill=(30, 32, 36))
    draw.rectangle([0, h-12, w, h], fill=(30, 32, 36))
    draw.rectangle([0, 0, 12, h], fill=(30, 32, 36))
    draw.rectangle([w-12, 0, w, h], fill=(30, 32, 36))
    draw.rectangle([w//2-6, 0, w//2+6, h], fill=(30, 32, 36))

    draw.rectangle([20, 320, w-20, 335], fill=(22, 24, 28))
    for bx in [30, 110, 180, 280, 360, 430]:
        draw.rectangle([bx, 260, bx + random.randint(55, 75), 320], fill=(48, 40, 30))
        draw.rectangle([bx, 260, bx + 20, 320], fill=(65, 55, 40))

    neon_core = (255, 80, 40)
    neon_glow = (255, 160, 120)
    neon_outer = (220, 40, 20)

    for t in range(0, 360, 2):
        rad = math.radians(t)
        x = 16 * math.sin(rad)**3
        y = -(13 * math.cos(rad) - 5 * math.cos(2*rad) - 2 * math.cos(3*rad) - math.cos(4*rad))
        hx = 135 + x * 6.8
        hy = 155 + y * 6.8
        draw.ellipse([hx-9, hy-9, hx+9, hy+9], fill=neon_outer)
        draw.ellipse([hx-5, hy-5, hx+5, hy+5], fill=neon_glow)
        draw.ellipse([hx-2, hy-2, hx+2, hy+2], fill=neon_core)

    font_open = get_font(52, bold=True)
    font_24 = get_font(40, bold=True)

    draw.rectangle([270, 50, 490, 230], outline=(255, 80, 40), width=6)
    draw.rectangle([276, 56, 484, 224], outline=(255, 180, 140), width=2)
    draw.text((310, 75), "OPEN", fill=(255, 50, 30), font=font_open)
    draw.text((308, 72), "OPEN", fill=(255, 230, 50), font=font_open)
    draw.text((295, 145), "24 HRS", fill=(40, 140, 255), font=font_24)
    draw.text((293, 142), "24 HRS", fill=(180, 240, 255), font=font_24)

    im.save(os.path.join(OUT_DIR, "tex_window_display.png"))
    print("Created tex_window_display.png")

# 9. tex_storm_grate.png (512x512) - High-contrast cast-iron slotted drain
def make_storm_grate():
    w, h = 512, 512
    im = Image.new("RGB", (w, h), (10, 12, 14)) # Deep drainage pit
    draw = ImageDraw.Draw(im)
    
    rim_col = (110, 115, 125) # Silver-gray iron highlight rim
    rim_edge = (35, 38, 42)
    draw.rectangle([12, 12, w-12, h-12], outline=rim_col, width=36)
    draw.rectangle([32, 32, w-32, h-32], outline=rim_edge, width=6)
    
    bar_w = 32
    spacing = (w - 72) // 8
    for i in range(1, 8):
        bx = 36 + i * spacing - bar_w // 2
        draw.rectangle([bx, 36, bx + bar_w, h-36], fill=rim_col)
        draw.line([(bx + 3, 36), (bx + 3, h-36)], fill=(185, 190, 200), width=4)
        draw.line([(bx + bar_w - 3, 36), (bx + bar_w - 3, h-36)], fill=(20, 22, 25), width=4)
        
        for _ in range(8):
            ry = random.randint(40, h-40)
            draw.ellipse([bx + 4, ry, bx + 14, ry + 5], fill=(155, 90, 45))
            
    draw.ellipse([45, 410, 95, 445], fill=(160, 95, 35))
    draw.ellipse([420, 50, 470, 90], fill=(140, 80, 28))

    im.save(os.path.join(OUT_DIR, "tex_storm_grate.png"))
    print("Created tex_storm_grate.png")

# 10. tex_manhole.png (512x512)
def make_manhole():
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    
    cx, cy, r = w//2, h//2, 230
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(85, 90, 98, 255), outline=(35, 38, 44, 255), width=8)
    draw.ellipse([cx - r + 24, cy - r + 24, cx + r - 24, cy + r - 24], outline=(125, 130, 140, 255), width=4)
    
    r_in = r - 45
    draw.ellipse([cx - r_in, cy - r_in, cx + r_in, cy + r_in], fill=(65, 70, 78, 255), outline=(32, 35, 40, 255), width=6)
    
    tread_mask = Image.new("RGBA", (w, h), (0,0,0,0))
    t_draw = ImageDraw.Draw(tread_mask)
    for d in range(-w, w*2, 24):
        t_draw.line([(d, 0), (d + h, h)], fill=(110, 115, 125, 180), width=3)
        t_draw.line([(d, h), (d + h, 0)], fill=(110, 115, 125, 180), width=3)
        
    circle_clip = Image.new("L", (w, h), 0)
    ImageDraw.Draw(circle_clip).ellipse([cx - r_in + 8, cy - r_in + 8, cx + r_in - 8, cy + r_in - 8], fill=255)
    im.paste(tread_mask, (0,0), circle_clip)
    
    font_curved = get_font(22, bold=True)
    draw.text((cx - 75, cy - 35), "CITY SEWER", fill=(195, 200, 210, 255), font=font_curved)
    draw.text((cx - 70, cy + 8), "WATER & POWER", fill=(165, 170, 180, 255), font=get_font(16, bold=True))
    
    draw.rectangle([cx - 15, cy - r_in + 18, cx + 15, cy - r_in + 32], fill=(15, 15, 18, 255))
    draw.rectangle([cx - 15, cy + r_in - 32, cx + 15, cy + r_in - 18], fill=(15, 15, 18, 255))

    im.save(os.path.join(OUT_DIR, "tex_manhole.png"))
    print("Created tex_manhole.png")

if __name__ == "__main__":
    make_asphalt()
    make_sidewalk()
    make_brick()
    make_cardboard()
    make_blue_bin()
    make_amber_bin()
    make_storefront_fascia()
    make_window_display()
    make_storm_grate()
    make_manhole()
    print("ALL URBAN TEXTURES GENERATED SUCCESSFULLY!")
