#!/usr/bin/env python3
"""
scripts/generate_storefront_texture.py
Generates 2048x2048 production-quality texture atlas for the Gears District:
- Zone 1: Main Fascia Signboard: "BURNSIDE SALVAGE & REPAIR" + Gear Emblem + Stencils
- Zone 2: Rooftop Billboard: "LUNG-RENEW 4.0" with detailed Cyber Anime Mascot, Aero-Inhaler & Telemetry
- Zone 3: Roll-up Corrugated Garage Door & Workshop Interior Depth (Vehicle Lift, Hoist, Tool Chest, Drums)
- Zone 4: Pedestrian Service Door with Security Glass, Kickplate, "PARTS TOOLS SERVICE" & Neon "OPEN"
- Zone 5: Right Wall Stencils: "SCRAP REBUILDS KEEPS CITIES ALIVE." & "DELIVER SCAVENGE REPAIR SURVIVE"
- Zone 6: Signal Quota Dispensary Kiosk: Biometric HUD, Keypad, "DEBT FUELS PROGRESS", Hazard Stripes
- Zone 7: Scrap Dumpster Panels: "BURN SALVAGE", Hazard Triangle, Heavy Steel Stiffeners & Wear
- Zone 8: Surveillance Utility Pole: "ASHFORD AVE", "DISTRICT 13", "FB-HV-04 HIGH VOLTAGE // 12.4 kV"
- Zone 9: Environmental Shading Atlas: Authentic Red Industrial Brick Masonry, Corrugated Metal, Scrap Shards, Road Stencil "GD-13"
"""

import os
import math
import random
from PIL import Image, ImageDraw, ImageFont

def get_font(size, bold=True):
    font_paths = [
        "/System/Library/Fonts/Supplemental/Impact.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNSMono.ttf",
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                pass
    return ImageFont.load_default()

def draw_gear_icon(draw, cx, cy, radius, teeth=8, fill_color=(20, 20, 24), hole_radius=None):
    if hole_radius is None:
        hole_radius = radius * 0.42
    
    for i in range(teeth):
        ang = i * (2.0 * math.pi / teeth)
        t_w = radius * 0.38
        t_h = radius * 0.38
        x0 = cx + math.cos(ang) * (radius - 2)
        y0 = cy + math.sin(ang) * (radius - 2)
        draw.rectangle([x0 - t_w/2, y0 - t_h/2, x0 + t_w/2, y0 + t_h/2], fill=fill_color)
    
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=fill_color)
    draw.ellipse([cx - hole_radius, cy - hole_radius, cx + hole_radius, cy + hole_radius], fill=(235, 230, 218))
    # Bolt center
    draw.ellipse([cx - hole_radius * 0.45, cy - hole_radius * 0.45, cx + hole_radius * 0.45, cy + hole_radius * 0.45], fill=fill_color)

def draw_hazard_stripes(draw, bbox, stripe_w=24, col1=(235, 175, 25), col2=(24, 25, 30)):
    x0, y0, x1, y1 = bbox
    w = x1 - x0
    h = y1 - y0
    
    stripes = Image.new("RGBA", (w, h), col1)
    s_draw = ImageDraw.Draw(stripes)
    
    diag = int(w + h + stripe_w * 4)
    for sx in range(-diag, diag, stripe_w * 2):
        points = [
            (sx, 0),
            (sx + stripe_w, 0),
            (sx + stripe_w + h, h),
            (sx + h, h)
        ]
        s_draw.polygon(points, fill=col2)
    
    return stripes

def draw_anime_cyber_mascot(draw, cx, cy, scale=1.0):
    """Draws a high-detail cyberpunk anime mascot wearing pilot headset & aero-inhaler."""
    # Head & Neck
    neck_col = (235, 195, 175, 255)
    skin_col = (255, 224, 205, 255)
    shadow_col = (225, 180, 160, 255)
    
    # Neck & Choker
    draw.polygon([
        (cx - 24 * scale, cy + 30 * scale),
        (cx + 18 * scale, cy + 30 * scale),
        (cx + 26 * scale, cy + 85 * scale),
        (cx - 30 * scale, cy + 85 * scale)
    ], fill=neck_col)
    # Tactical choker collar
    draw.rectangle([cx - 28 * scale, cy + 60 * scale, cx + 22 * scale, cy + 76 * scale], fill=(30, 34, 42, 255))
    draw.ellipse([cx - 8 * scale, cy + 64 * scale, cx + 2 * scale, cy + 72 * scale], fill=(0, 225, 255, 255)) # cyan LED

    # Face base
    face_pts = [
        (cx - 45 * scale, cy - 35 * scale),
        (cx + 35 * scale, cy - 35 * scale),
        (cx + 42 * scale, cy + 10 * scale),
        (cx + 25 * scale, cy + 45 * scale),
        (cx, cy + 62 * scale), # chin
        (cx - 32 * scale, cy + 42 * scale),
        (cx - 48 * scale, cy + 12 * scale),
    ]
    draw.polygon(face_pts, fill=skin_col)
    # Jawline shadow
    draw.polygon([
        (cx - 32 * scale, cy + 42 * scale),
        (cx, cy + 62 * scale),
        (cx + 25 * scale, cy + 45 * scale),
        (cx + 15 * scale, cy + 38 * scale),
        (cx - 22 * scale, cy + 38 * scale)
    ], fill=shadow_col)

    # Large Anime Eyes (Left eye visible, right eye 3/4)
    # Eyeball whites
    draw.ellipse([cx - 32 * scale, cy - 8 * scale, cx - 8 * scale, cy + 24 * scale], fill=(255, 255, 255, 255))
    draw.ellipse([cx + 6 * scale, cy - 8 * scale, cx + 28 * scale, cy + 24 * scale], fill=(255, 255, 255, 255))
    
    # Green Irises
    draw.ellipse([cx - 28 * scale, cy - 4 * scale, cx - 12 * scale, cy + 22 * scale], fill=(20, 155, 95, 255))
    draw.ellipse([cx + 10 * scale, cy - 4 * scale, cx + 24 * scale, cy + 22 * scale], fill=(20, 155, 95, 255))
    # Pupils
    draw.ellipse([cx - 24 * scale, cy + 2 * scale, cx - 16 * scale, cy + 16 * scale], fill=(12, 45, 28, 255))
    draw.ellipse([cx + 14 * scale, cy + 2 * scale, cx + 20 * scale, cy + 16 * scale], fill=(12, 45, 28, 255))
    # Catchlights (Sparkle)
    draw.ellipse([cx - 26 * scale, cy - 1 * scale, cx - 20 * scale, cy + 6 * scale], fill=(255, 255, 255, 255))
    draw.ellipse([cx - 18 * scale, cy + 12 * scale, cx - 14 * scale, cy + 16 * scale], fill=(180, 255, 220, 255))
    draw.ellipse([cx + 12 * scale, cy - 1 * scale, cx + 18 * scale, cy + 6 * scale], fill=(255, 255, 255, 255))
    draw.ellipse([cx + 19 * scale, cy + 12 * scale, cx + 22 * scale, cy + 16 * scale], fill=(180, 255, 220, 255))

    # Upper Eyelashes (Thick comic ink)
    draw.arc([cx - 36 * scale, cy - 14 * scale, cx - 4 * scale, cy + 16 * scale], 190, 360, fill=(20, 24, 30, 255), width=int(5 * scale))
    draw.arc([cx + 2 * scale, cy - 14 * scale, cx + 32 * scale, cy + 16 * scale], 180, 350, fill=(20, 24, 30, 255), width=int(5 * scale))
    # Eyebrows
    draw.arc([cx - 34 * scale, cy - 24 * scale, cx - 6 * scale, cy - 4 * scale], 200, 340, fill=(35, 120, 60, 255), width=int(4 * scale))
    draw.arc([cx + 4 * scale, cy - 24 * scale, cx + 30 * scale, cy - 4 * scale], 190, 330, fill=(35, 120, 60, 255), width=int(4 * scale))

    # Nose & Mouth
    draw.ellipse([cx - 1 * scale, cy + 22 * scale, cx + 3 * scale, cy + 26 * scale], fill=(200, 140, 120, 255))
    draw.arc([cx - 10 * scale, cy + 32 * scale, cx + 14 * scale, cy + 48 * scale], 25, 155, fill=(190, 60, 55, 255), width=int(4 * scale))

    # Spiky Cyber Bangs (Lime / Emerald Hair)
    hair_col = (115, 185, 45, 255)
    hair_hi = (165, 235, 80, 255)
    hair_shadow = (65, 125, 25, 255)

    # Hair strands
    draw.polygon([(cx - 50 * scale, cy - 30 * scale), (cx - 35 * scale, cy + 10 * scale), (cx - 25 * scale, cy - 20 * scale)], fill=hair_col)
    draw.polygon([(cx - 30 * scale, cy - 35 * scale), (cx - 12 * scale, cy + 8 * scale), (cx - 5 * scale, cy - 25 * scale)], fill=hair_hi)
    draw.polygon([(cx - 10 * scale, cy - 35 * scale), (cx + 8 * scale, cy + 12 * scale), (cx + 15 * scale, cy - 25 * scale)], fill=hair_col)
    draw.polygon([(cx + 10 * scale, cy - 35 * scale), (cx + 28 * scale, cy + 6 * scale), (cx + 38 * scale, cy - 20 * scale)], fill=hair_shadow)
    # Top hair volume
    draw.arc([cx - 55 * scale, cy - 65 * scale, cx + 50 * scale, cy + 5 * scale], 160, 380, fill=hair_col, width=int(28 * scale))

    # Cyber Pilot Headset (Left side ear cup)
    ec_x, ec_y = cx - 48 * scale, cy + 2 * scale
    draw.ellipse([ec_x - 22 * scale, ec_y - 28 * scale, ec_x + 22 * scale, ec_y + 28 * scale], fill=(42, 46, 54, 255), outline=(15, 16, 20, 255), width=int(3 * scale))
    draw.ellipse([ec_x - 14 * scale, ec_y - 20 * scale, ec_x + 14 * scale, ec_y + 20 * scale], fill=(65, 72, 85, 255))
    draw.ellipse([ec_x - 7 * scale, ec_y - 10 * scale, ec_x + 7 * scale, ec_y + 10 * scale], fill=(0, 230, 255, 255)) # Glowing cyan hub
    # Headband
    draw.arc([cx - 58 * scale, cy - 72 * scale, cx + 46 * scale, cy + 10 * scale], 180, 360, fill=(35, 38, 45, 255), width=int(12 * scale))
    # Boom Microphone sweeping forward to mouth
    draw.arc([ec_x - 5 * scale, ec_y - 5 * scale, cx + 25 * scale, cy + 50 * scale], 30, 130, fill=(180, 185, 195, 255), width=int(4 * scale))
    draw.rectangle([cx + 12 * scale, cy + 34 * scale, cx + 24 * scale, cy + 42 * scale], fill=(30, 32, 38, 255))
    draw.ellipse([cx + 22 * scale, cy + 36 * scale, cx + 26 * scale, cy + 40 * scale], fill=(0, 240, 255, 255))

    # Aero-Inhaler Device in hand / foreground
    inh_x, inh_y = cx + 45 * scale, cy + 30 * scale
    # Hand fingers holding inhaler
    draw.ellipse([inh_x - 12 * scale, cy + 45 * scale, inh_x + 10 * scale, cy + 65 * scale], fill=skin_col)
    # Inhaler body
    draw.rounded_rectangle([inh_x, inh_y, inh_x + 36 * scale, inh_y + 75 * scale], radius=int(6 * scale), fill=(245, 248, 255, 255), outline=(25, 35, 50, 255), width=int(3 * scale))
    # Cyan aerosol cartridge top
    draw.rounded_rectangle([inh_x + 5 * scale, inh_y - 18 * scale, inh_x + 31 * scale, inh_y], radius=int(4 * scale), fill=(0, 205, 245, 255), outline=(20, 30, 45, 255), width=int(2 * scale))
    # Mouthpiece pointing toward mouth
    draw.rectangle([inh_x - 18 * scale, inh_y + 40 * scale, inh_x, inh_y + 62 * scale], fill=(225, 230, 240, 255), outline=(25, 35, 50, 255), width=int(2 * scale))
    # Aerosol mist plume
    for pr in (12, 22, 32):
        draw.arc([inh_x - (25 + pr) * scale, inh_y + (30 - pr/2) * scale, inh_x - 10 * scale, inh_y + (60 + pr/2) * scale], 120, 240, fill=(0, 225, 255, int(180 - pr * 4)), width=int(3 * scale))


def main():
    atlas_size = 2048
    atlas = Image.new("RGBA", (atlas_size, atlas_size), (24, 26, 30, 255))
    draw = ImageDraw.Draw(atlas)

    font_giant = get_font(72, bold=True)
    font_huge = get_font(54, bold=True)
    font_large = get_font(40, bold=True)
    font_med = get_font(28, bold=True)
    font_small = get_font(20, bold=True)
    font_tiny = get_font(14, bold=True)

    # =========================================================================
    # ZONE 1: Main Fascia Sign "BURNSIDE SALVAGE & REPAIR" (20, 20) -> (1220, 320)
    # =========================================================================
    fx0, fy0, fx1, fy1 = 20, 20, 1220, 320
    # Outer steel riveted perimeter backboard — near-black charcoal #1C1410
    draw.rectangle([fx0, fy0, fx1, fy1], fill=(22, 18, 14, 255), outline=(10, 10, 12, 255), width=6)
    # Perimeter rivets — warm steel
    for bx in range(fx0 + 15, fx1, 45):
        draw.ellipse([bx - 3, fy0 + 5, bx + 3, fy0 + 11], fill=(120, 115, 108, 255), outline=(8, 8, 10, 255))
        draw.ellipse([bx - 3, fy1 - 11, bx + 3, fy1 - 5], fill=(120, 115, 108, 255), outline=(8, 8, 10, 255))
    for by in range(fy0 + 15, fy1, 35):
        draw.ellipse([fx0 + 5, by - 3, fx0 + 11, by + 3], fill=(120, 115, 108, 255), outline=(8, 8, 10, 255))
        draw.ellipse([fx1 - 11, by - 3, fx1 - 5, by + 3], fill=(120, 115, 108, 255), outline=(8, 8, 10, 255))

    # Inner signboard background — DARK charcoal #1C1410, same as outer (matches reference B panel D)
    draw.rectangle([fx0 + 18, fy0 + 18, fx1 - 18, fy1 - 18], fill=(28, 22, 16, 255))
    # Subtle rust drip streaks (vertical, very dark, almost invisible)
    for rx in range(fx0 + 40, fx1 - 40, 90):
        for dy in range(0, 36, 3):
            draw.line([(rx, fy0 + 18 + dy), (rx + 2, fy0 + 18 + dy + 3)],
                      fill=(55, 32, 16, 160 - dy * 4))

    # Heavy mechanical 8-tooth gear+wrench emblem — ivory on dark, bold readable icon
    gx, gy, gr = fx0 + 112, fy0 + 145, 90
    # Outer ink ring shadow
    draw_gear_icon(draw, gx + 2, gy + 2, gr + 4, teeth=8, fill_color=(10, 8, 6), hole_radius=0)
    # Main gear — warm ivory
    draw_gear_icon(draw, gx, gy, gr, teeth=8, fill_color=(220, 210, 180))
    # Center hub hole — dark
    draw_gear_icon(draw, gx, gy, int(gr * 0.32), teeth=0, fill_color=(28, 22, 16), hole_radius=0)
    # Wrench bar crossing through gear
    draw.rectangle([gx - gr + 14, gy - 9, gx + gr - 14, gy + 9], fill=(28, 22, 16, 255))
    draw.ellipse([gx - gr + 4, gy - 20, gx - gr + 32, gy + 20], fill=(220, 210, 180, 255), outline=(10, 8, 6, 255), width=3)
    draw.ellipse([gx + gr - 32, gy - 20, gx + gr - 4, gy + 20], fill=(220, 210, 180, 255), outline=(10, 8, 6, 255), width=3)

    # "BURNSIDE" — IVORY warm text on dark backing (matches reference B)
    # Ink shadow for letterform edges
    draw.text((fx0 + 228, fy0 + 48), "BURNSIDE", fill=(8, 6, 4, 255), font=font_giant)  # shadow
    draw.text((fx0 + 225, fy0 + 45), "BURNSIDE", fill=(237, 224, 184, 255), font=font_giant)  # ivory
    # Stencil bridges through letters (dark background color)
    draw.rectangle([fx0 + 270, fy0 + 44, fx0 + 275, fy0 + 118], fill=(28, 22, 16, 255))
    draw.rectangle([fx0 + 380, fy0 + 44, fx0 + 385, fy0 + 118], fill=(28, 22, 16, 255))
    draw.rectangle([fx0 + 478, fy0 + 44, fx0 + 483, fy0 + 118], fill=(28, 22, 16, 255))

    # Machinery-Yellow Enamel Badge Box: "SALVAGE & REPAIR" — #F5C400 saturated, weathered
    sb_x0, sb_y0, sb_x1, sb_y1 = fx0 + 622, fy0 + 48, fx1 - 22, fy0 + 158
    # Thin dark border ring
    draw.rectangle([sb_x0 - 4, sb_y0 - 4, sb_x1 + 4, sb_y1 + 4], fill=(10, 8, 6, 255))
    # Main yellow panel — slightly warm/aged (not pure F5C400) to avoid emissive look
    draw.rectangle([sb_x0, sb_y0, sb_x1, sb_y1], fill=(232, 182, 12, 255))
    # Weathering grunge — scattered dark speckles across yellow panel
    import random; rng = random.Random(42)
    for _ in range(220):
        wx = rng.randint(sb_x0 + 2, sb_x1 - 2)
        wy = rng.randint(sb_y0 + 2, sb_y1 - 2)
        draw.ellipse([wx, wy, wx + 2, wy + 2], fill=(160, 130, 8, 90))
    # Inner border highlight
    draw.rectangle([sb_x0 + 4, sb_y0 + 4, sb_x1 - 4, sb_y1 - 4], outline=(245, 210, 40, 255), width=2)
    draw.text((sb_x0 + 14, sb_y0 + 18), "SALVAGE & REPAIR", fill=(10, 8, 6, 255), font=font_huge)

    # Subtitle: "WE BUY UNCLAIMED DRIVES & ALTERNATORS" — ivory on dark, larger for readability
    draw.text((fx0 + 228, fy0 + 174), "WE BUY UNCLAIMED DRIVES & ALTERNATORS",
              fill=(8, 6, 4, 255), font=font_med)  # shadow
    draw.text((fx0 + 226, fy0 + 172), "WE BUY UNCLAIMED DRIVES & ALTERNATORS",
              fill=(195, 186, 164, 255), font=font_med)  # ivory tinted

    # Lower hazard caution strip — orange text on near-black
    draw.rectangle([fx0 + 18, fy1 - 44, fx1 - 18, fy1 - 18], fill=(18, 14, 10, 255))
    draw.text((fx0 + 110, fy1 - 40),
              "LICENSED MUNICIPAL RECLAMATION FACILITY // DISTRICT 13 // SURVEILLANCE ACTIVE",
              fill=(235, 165, 22, 255), font=font_small)


    # =========================================================================
    # ZONE 2: Rooftop Billboard "LUNG-RENEW 4.0" (1240, 20) -> (2028, 460)
    # =========================================================================
    bx0, by0, bx1, by1 = 1240, 20, 2028, 460
    # Steel frame
    draw.rectangle([bx0, by0, bx1, by1], fill=(24, 28, 36, 255), outline=(12, 14, 18, 255), width=6)

    # Two-tone rich saturated gradient: deep teal to rich mint (prevents sunlight washout)
    for x in range(bx0 + 8, bx1 - 8):
        t = (x - bx0) / (bx1 - bx0)
        c_r = int(14 + t * 65)
        c_g = int(72 + t * 88)
        c_b = int(92 + t * 50)
        draw.line([(x, by0 + 8), (x, by1 - 8)], fill=(c_r, c_g, c_b, 255))

    # Top corporate telemetry banner
    draw.rectangle([bx0 + 8, by0 + 8, bx1 - 8, by0 + 42], fill=(12, 24, 45, 255))
    draw.text((bx0 + 25, by0 + 14), "BIOTECH DYNAMICS CORP // SEC-CLEARANCE 09 // MUNICIPAL AIR CONTRACT GD-13", fill=(0, 210, 240, 255), font=font_tiny)

    # Anime Cyber Mascot (Left Side)
    draw_anime_cyber_mascot(draw, bx0 + 130, by0 + 215, scale=1.35)

    # Typography (Right Side)
    # Slogan - high-contrast dark tones against teal/mint background
    draw.text((bx0 + 270, by0 + 58), "LUNG-RENEW 4.0:", fill=(8, 28, 75, 255), font=font_huge)
    draw.text((bx0 + 272, by0 + 128), "Breathe Easy with", fill=(15, 20, 28, 255), font=font_large)
    draw.text((bx0 + 272, by0 + 180), "15% Fewer Ads Per Inhale!", fill=(6, 85, 45, 255), font=font_large)

    # Saturated Blue Pill Button: "Subscribers Only ///"
    px0, py0, px1, py1 = bx0 + 290, by0 + 295, bx1 - 50, by0 + 380
    draw.rounded_rectangle([px0, py0, px1, py1], radius=18, fill=(18, 75, 185, 255), outline=(8, 25, 75, 255), width=4)
    draw.text((px0 + 55, py0 + 18), "Subscribers Only ///", fill=(245, 248, 255, 255), font=font_med)

    # Micro-fine print at bottom
    draw.text((bx0 + 272, by0 + 400), "*Standard bio-contract includes 4 mandatory sponsored intervals per breath cycle.", fill=(35, 52, 65, 255), font=font_tiny)


    # =========================================================================
    # ZONE 3: Corrugated Garage Door & Workshop Interior (20, 360) -> (780, 980)
    # =========================================================================
    gx0, gy0, gx1, gy1 = 20, 360, 780, 980
    draw.rectangle([gx0, gy0, gx1, gy1], fill=(22, 24, 30, 255), outline=(18, 20, 24, 255), width=6)

    # Top Half: Rolled-up Corrugated Shutter Curtain
    door_split_y = gy0 + 250
    draw.rectangle([gx0, gy0, gx1, door_split_y], fill=(75, 80, 88, 255))
    for sy in range(gy0 + 6, door_split_y, 14):
        draw.rectangle([gx0 + 6, sy, gx1 - 6, sy + 8], fill=(115, 122, 132, 255))
        draw.rectangle([gx0 + 6, sy + 8, gx1 - 6, sy + 14], fill=(42, 45, 52, 255))
    # Stencil on rolled-up door: "BURN SALVAGE"
    draw_gear_icon(draw, (gx0 + gx1)//2 - 120, gy0 + 125, 38, teeth=8, fill_color=(235, 230, 215))
    draw.text(((gx0 + gx1)//2 - 60, gy0 + 95), "BURN", fill=(235, 230, 215, 255), font=font_huge)
    draw.text(((gx0 + gx1)//2 - 60, gy0 + 148), "SALVAGE", fill=(235, 230, 215, 255), font=font_huge)

    # Bottom Half: Workshop Interior Depth
    draw.rectangle([gx0, door_split_y, gx1, gy1], fill=(16, 18, 22, 255))
    # Downward warm conical worklights from ceiling
    for lx in (gx0 + 180, gx0 + 540):
        draw.polygon([(lx, door_split_y), (lx - 120, gy1), (lx + 120, gy1)], fill=(245, 185, 45, 35))
        draw.ellipse([lx - 15, door_split_y - 8, lx + 15, door_split_y + 8], fill=(255, 220, 120, 255))

    # 2-Post Automotive Vehicle Lift (Center)
    draw.rectangle([gx0 + 220, door_split_y + 20, gx0 + 245, gy1 - 10], fill=(225, 160, 20, 255)) # yellow left post
    draw.rectangle([gx0 + 515, door_split_y + 20, gx0 + 540, gy1 - 10], fill=(225, 160, 20, 255)) # yellow right post
    # Muscle Car chassis elevated on lift
    draw.polygon([
        (gx0 + 260, door_split_y + 140),
        (gx0 + 320, door_split_y + 90),
        (gx0 + 440, door_split_y + 90),
        (gx0 + 500, door_split_y + 140),
        (gx0 + 500, door_split_y + 175),
        (gx0 + 260, door_split_y + 175),
    ], fill=(45, 48, 55, 255), outline=(15, 16, 20, 255), width=3)
    # Lift arms
    draw.rectangle([gx0 + 240, door_split_y + 160, gx0 + 520, door_split_y + 175], fill=(225, 160, 20, 255))

    # Red Rolling Tool Chest (Left foreground)
    draw.rectangle([gx0 + 60, door_split_y + 180, gx0 + 180, gy1 - 15], fill=(185, 35, 25, 255), outline=(15, 15, 18, 255), width=3)
    for dy in range(door_split_y + 195, gy1 - 25, 18):
        draw.line([(gx0 + 75, dy), (gx0 + 165, dy)], fill=(220, 225, 235, 255), width=3)

    # Yellow Oil Drums (Right foreground)
    draw.rectangle([gx0 + 590, door_split_y + 210, gx0 + 660, gy1 - 15], fill=(225, 165, 25, 255), outline=(15, 15, 18, 255), width=3)
    draw.text((gx0 + 602, door_split_y + 240), "BIO", fill=(20, 22, 26, 255), font=font_small)


    # =========================================================================
    # ZONE 4: Pedestrian Service Door & Neon OPEN (820, 360) -> (1240, 980)
    # =========================================================================
    dx0, dy0, dx1, dy1 = 820, 360, 1240, 980
    draw.rectangle([dx0, dy0, dx1, dy1], fill=(45, 48, 56, 255), outline=(18, 20, 24, 255), width=6)
    # Recessed door panel
    draw.rectangle([dx0 + 16, dy0 + 16, dx1 - 16, dy1 - 16], fill=(32, 35, 42, 255))

    # Kickplate at bottom
    draw.rectangle([dx0 + 25, dy1 - 180, dx1 - 25, dy1 - 25], fill=(85, 90, 100, 255), outline=(20, 22, 26, 255), width=4)
    for kx in range(dx0 + 45, dx1 - 35, 40):
        draw.ellipse([kx, dy1 - 160, kx + 8, dy1 - 152], fill=(180, 185, 195, 255))
        draw.ellipse([kx, dy1 - 50, kx + 8, dy1 - 42], fill=(180, 185, 195, 255))

    # Security glass window with diagonal glare
    wx0, wy0, wx1, wy1 = dx0 + 60, dy0 + 55, dx1 - 60, dy0 + 235
    draw.rectangle([wx0, wy0, wx1, wy1], fill=(15, 28, 38, 255), outline=(15, 16, 20, 255), width=5)
    draw.polygon([(wx0 + 20, wy1 - 10), (wx1 - 40, wy0 + 10), (wx1 - 10, wy0 + 10), (wx0 + 50, wy1 - 10)], fill=(0, 225, 255, 90))
    for bx in range(wx0 + 35, wx1, 35):
        draw.line([(bx, wy0), (bx, wy1)], fill=(75, 82, 92, 255), width=4)

    # Door Stencil
    draw.text((dx0 + 75, dy0 + 265), "PARTS", fill=(215, 220, 230, 255), font=font_large)
    draw.text((dx0 + 75, dy0 + 320), "TOOLS", fill=(215, 220, 230, 255), font=font_large)
    draw.text((dx0 + 75, dy0 + 375), "SERVICE", fill=(215, 220, 230, 255), font=font_large)

    # Illuminated Neon "OPEN" Sign Box
    nx0, ny0, nx1, ny1 = dx0 + 65, dy0 + 445, dx1 - 65, dy0 + 545
    draw.rectangle([nx0, ny0, nx1, ny1], fill=(12, 14, 18, 255), outline=(225, 45, 30, 255), width=5)
    draw.rectangle([nx0 + 8, ny0 + 8, nx1 - 8, ny1 - 8], outline=(0, 220, 255, 200), width=3)
    draw.text((nx0 + 32, ny0 + 16), "OPEN", fill=(255, 45, 35, 255), font=font_huge)

    # Heavy Brass Door Handle
    draw.rectangle([dx1 - 65, dy0 + 340, dx1 - 42, dy0 + 460], fill=(215, 175, 55, 255), outline=(15, 15, 18, 255), width=3)
    draw.ellipse([dx1 - 58, dy0 + 310, dx1 - 50, dy0 + 318], fill=(10, 10, 12, 255))


    # =========================================================================
    # ZONE 5: Wall Stencils, Propaganda Poster, GO-13 Billboard & Parapet (1260, 480) -> (2028, 1000)
    # =========================================================================
    # 5A. Right Wall Stencils & Industrial Brick (1260, 480) -> (1680, 1000)
    wx0, wy0, wx1, wy1 = 1260, 480, 1680, 1000
    draw.rectangle([wx0, wy0, wx1, wy1], fill=(76, 42, 34, 255), outline=(16, 18, 22, 255), width=4)
    brick_h, brick_w = 22, 54
    for b_row, by in enumerate(range(wy0, wy1, brick_h)):
        offset = (brick_w // 2) if (b_row % 2 == 1) else 0
        draw.line([(wx0, by), (wx1, by)], fill=(24, 22, 20, 255), width=2)
        for bx in range(wx0 + offset, wx1, brick_w):
            draw.line([(bx, by), (bx, by + brick_h)], fill=(24, 22, 20, 255), width=2)

    # Weathered Stencil: "SCRAP REBUILDS KEEPS CITIES ALIVE."
    draw.ellipse([wx0 + 30, wy0 + 60, wx0 + 390, wy0 + 420], fill=(28, 25, 24, 160))
    st_words = ["SCRAP", "REBUILDS", "KEEPS", "CITIES", "ALIVE."]
    for idx, w in enumerate(st_words):
        wy = wy0 + 35 + idx * 62
        draw.text((wx0 + 25, wy), w, fill=(225, 220, 212, 245), font=font_huge)
        # Stencil bridges
        draw.rectangle([wx0 + 45, wy, wx0 + 49, wy + 55], fill=(76, 42, 34, 255))
        draw.rectangle([wx0 + 135, wy, wx0 + 139, wy + 55], fill=(76, 42, 34, 255))

    # Secondary Yellow Stencil: "DELIVER // SCAVENGE // REPAIR // SURVIVE"
    st_yellow = ["DELIVER", "SCAVENGE", "REPAIR", "SURVIVE"]
    for idx, w in enumerate(st_yellow):
        wy = wy0 + 70 + idx * 54
        draw.text((wx0 + 265, wy), w, fill=(235, 175, 25, 240), font=font_med)

    # Hazard stripes band at bottom of right wall
    stripes_wall = draw_hazard_stripes(draw, (0, 0, wx1 - wx0, 48), stripe_w=20)
    atlas.paste(stripes_wall, (wx0, wy1 - 52))

    # 5B. Front Left Pillar Propaganda Poster (1690, 480) -> (1860, 1000)
    # "A CLEANER // BRIGHTER // STRONGER // GEARS DISTRICT"
    px0, py0, px1, py1 = 1690, 480, 1860, 1000
    # Soot brick border
    draw.rectangle([px0, py0, px1, py1], fill=(62, 35, 28, 255), outline=(18, 20, 24, 255), width=3)
    # Weathered paper poster body
    draw.rectangle([px0 + 8, py0 + 15, px1 - 8, py1 - 25], fill=(215, 205, 178, 255), outline=(32, 34, 40, 255), width=3)
    # Corner tape pieces
    for tx, ty in [(px0 + 4, py0 + 10), (px1 - 24, py0 + 10), (px0 + 4, py1 - 35), (px1 - 24, py1 - 35)]:
        draw.rectangle([tx, ty, tx + 20, ty + 12], fill=(185, 175, 140, 220))
    # Poster header emblem (Municipal gear with surveillance eye)
    draw_gear_icon(draw, (px0 + px1) // 2, py0 + 65, 32, teeth=8, fill_color=(20, 24, 30))
    draw.ellipse([(px0 + px1) // 2 - 12, py0 + 53, (px0 + px1) // 2 + 12, py0 + 77], fill=(235, 175, 25, 255))
    draw.ellipse([(px0 + px1) // 2 - 5, py0 + 60, (px0 + px1) // 2 + 5, py0 + 70], fill=(20, 24, 30, 255))
    # Slogan text
    draw.text((px0 + 22, py0 + 120), "A CLEANER", fill=(18, 20, 26, 255), font=font_med)
    draw.text((px0 + 18, py0 + 170), "BRIGHTER", fill=(18, 20, 26, 255), font=font_large)
    draw.text((px0 + 15, py0 + 225), "STRONGER", fill=(195, 35, 25, 255), font=font_large)
    draw.text((px0 + 32, py0 + 285), "GEARS", fill=(18, 20, 26, 255), font=font_huge)
    draw.text((px0 + 20, py0 + 345), "DISTRICT", fill=(18, 20, 26, 255), font=font_large)
    # Fine print / barcode
    draw.rectangle([px0 + 18, py0 + 410, px1 - 18, py0 + 445], fill=(30, 32, 38, 255))
    draw.text((px0 + 26, py0 + 418), "SEC-CODE 104-B", fill=(240, 245, 255, 255), font=font_tiny)
    draw.text((px0 + 15, py0 + 460), "RECYCLE // SURVIVE", fill=(55, 60, 70, 255), font=font_tiny)

    # 5C. Rooftop Secondary Billboard "GO-13 // SAME CITY. MORE DEBT." (1870, 480) -> (2028, 740)
    bx0, by0, bx1, by1 = 1870, 480, 2028, 740
    draw.rectangle([bx0, by0, bx1, by1], fill=(22, 24, 30, 255), outline=(12, 14, 18, 255), width=4)
    # Inner dark graphite panel
    draw.rectangle([bx0 + 6, by0 + 6, bx1 - 6, by1 - 6], fill=(35, 38, 46, 255))
    # Top orange warning bar
    draw.rectangle([bx0 + 6, by0 + 6, bx1 - 6, by0 + 32], fill=(235, 145, 20, 255))
    draw.text((bx0 + 18, by0 + 10), "MUNICIPAL RECLAMATION", fill=(15, 16, 20, 255), font=font_tiny)
    # "GO-13" in giant bold stencil
    draw.text((bx0 + 20, by0 + 42), "GO-13", fill=(245, 248, 255, 255), font=font_huge)
    # "SAME CITY."
    draw.text((bx0 + 22, by0 + 115), "SAME CITY.", fill=(225, 230, 240, 255), font=font_med)
    # "MORE DEBT."
    draw.text((bx0 + 20, by0 + 152), "MORE DEBT.", fill=(225, 45, 30, 255), font=font_large)
    # Barcode & hazard stripes bottom
    for b_idx in range(bx0 + 15, bx1 - 15, 6):
        draw.line([(b_idx, by0 + 208), (b_idx, by0 + 228)], fill=(220, 225, 235, 255), width=2)
    stripes_go13 = draw_hazard_stripes(draw, (0, 0, bx1 - bx0 - 12, 20), stripe_w=10)
    atlas.paste(stripes_go13, (bx0 + 6, by1 - 28))

    # 5D. Roof Parapet Stencil: "MOVEMENT KEEPS CITIES ALIVE." (1870, 750) -> (2028, 1000)
    rx0, ry0, rx1, ry1 = 1870, 750, 2028, 1000
    draw.rectangle([rx0, ry0, rx1, ry1], fill=(76, 42, 34, 255), outline=(16, 18, 22, 255), width=3)
    p_words = ["MOVEMENT", "KEEPS", "CITIES", "ALIVE."]
    for idx, w in enumerate(p_words):
        wy = ry0 + 18 + idx * 54
        draw.text((rx0 + 12, wy), w, fill=(245, 245, 240, 255), font=font_med)


    # =========================================================================
    # ZONE 6: Signal Quota Dispensary Kiosk (20, 1020) -> (720, 1600)
    # =========================================================================
    kx0, ky0, kx1, ky1 = 20, 1020, 720, 1600
    draw.rectangle([kx0, ky0, kx1, ky1], fill=(230, 165, 25, 255), outline=(20, 22, 26, 255), width=6)

    # Biometric Touchscreen Display
    sc_x0, sc_y0, sc_x1, sc_y1 = kx0 + 35, ky0 + 35, kx1 - 35, ky0 + 335
    draw.rectangle([sc_x0, sc_y0, sc_x1, sc_y1], fill=(10, 18, 28, 255), outline=(0, 210, 245, 255), width=5)

    draw.text((sc_x0 + 20, sc_y0 + 14), "SIGNAL QUOTA DISPENSARY", fill=(0, 230, 255, 255), font=font_med)
    draw.line([(sc_x0 + 15, sc_y0 + 52), (sc_x1 - 15, sc_y0 + 52)], fill=(0, 160, 200, 255), width=2)

    # Concentric biometric thumbprint scan circles
    f_cx, f_cy = (sc_x0 + sc_x1) // 2, sc_y0 + 135
    for fr in range(14, 60, 11):
        draw.arc([f_cx - fr, f_cy - fr * 1.25, f_cx + fr, f_cy + fr * 1.25], 25, 335, fill=(0, 240, 255, 255), width=3)
    # Crosshair reticle
    draw.line([(f_cx - 75, f_cy), (f_cx + 75, f_cy)], fill=(0, 180, 220, 180), width=2)
    draw.line([(f_cx, f_cy - 75), (f_cx, f_cy + 75)], fill=(0, 180, 220, 180), width=2)

    # Warning banner in red/yellow
    draw.rectangle([sc_x0 + 20, sc_y0 + 215, sc_x1 - 20, sc_y0 + 285], fill=(195, 35, 30, 255), outline=(245, 210, 30, 255), width=3)
    draw.text((sc_x0 + 40, sc_y0 + 225), "INSERT BIOMETRIC ID", fill=(255, 255, 255, 255), font=font_small)
    draw.text((sc_x0 + 30, sc_y0 + 252), "OR FACE FORFEITURE", fill=(255, 225, 30, 255), font=font_small)

    # 3x4 Backlit Numeric Keypad
    kp_x0, kp_y0 = kx0 + 55, ky0 + 355
    for row in range(4):
        for col in range(3):
            kpx = kp_x0 + col * 48
            kpy = kp_y0 + row * 40
            draw.rectangle([kpx, kpy, kpx + 38, kpy + 32], fill=(42, 46, 54, 255), outline=(18, 20, 24, 255), width=2)
            num_char = str((row * 3 + col + 1) % 10) if (row < 3 or col == 1) else ("*" if col == 0 else "#")
            draw.text((kpx + 12, kpy + 5), num_char, fill=(230, 235, 245, 255), font=font_small)

    # Side Stencils: "DEBT FUELS PROGRESS // GD-13"
    draw.text((kx0 + 245, ky0 + 360), "DEBT", fill=(20, 22, 26, 255), font=font_large)
    draw.text((kx0 + 245, ky0 + 410), "FUELS", fill=(20, 22, 26, 255), font=font_large)
    draw.text((kx0 + 245, ky0 + 460), "PROGRESS", fill=(20, 22, 26, 255), font=font_large)
    draw.text((kx0 + 480, ky0 + 460), "GD-13", fill=(20, 22, 26, 255), font=font_huge)

    # Hazard stripes on kiosk bottom
    stripes_kiosk = draw_hazard_stripes(draw, (0, 0, kx1 - kx0, 48), stripe_w=20)
    atlas.paste(stripes_kiosk, (kx0, ky1 - 50))


    # =========================================================================
    # ZONE 7: Scrap Dumpster Panels (740, 1020) -> (1420, 1600)
    # =========================================================================
    dx0, dy0, dx1, dy1 = 740, 1020, 1420, 1600
    # Weathered teal-blue industrial metal paint
    draw.rectangle([dx0, dy0, dx1, dy1], fill=(36, 68, 76, 255), outline=(15, 18, 22, 255), width=6)
    # Rust leaks from top rim
    for rx in range(dx0 + 40, dx1 - 40, 85):
        draw.polygon([(rx, dy0), (rx + 25, dy0), (rx + 12, dy0 + 60)], fill=(125, 62, 28, 180))

    # Reinforcement ribs
    for rx in range(dx0 + 90, dx1 - 60, 135):
        draw.rectangle([rx, dy0 + 25, rx + 28, dy1 - 25], fill=(26, 48, 55, 255), outline=(15, 18, 22, 255), width=3)

    # Dumpster Stencil: "BURN SALVAGE"
    ds_cx, ds_cy = (dx0 + dx1) // 2, (dy0 + dy1) // 2 - 35
    draw.ellipse([ds_cx - 190, ds_cy - 90, ds_cx + 190, ds_cy + 90], fill=(20, 38, 44, 220))
    draw_gear_icon(draw, ds_cx - 105, ds_cy, 52, teeth=8, fill_color=(235, 230, 215))
    draw.text((ds_cx - 35, ds_cy - 50), "BURN", fill=(235, 230, 215, 255), font=font_huge)
    draw.text((ds_cx - 35, ds_cy + 12), "SALVAGE", fill=(235, 230, 215, 255), font=font_huge)

    # Yellow Caution Triangle with "!"
    tx, ty, tr = dx0 + 130, dy1 - 120, 50
    draw.polygon([(tx, ty - tr), (tx + tr, ty + tr), (tx - tr, ty + tr)], fill=(235, 175, 25, 255), outline=(15, 15, 18, 255), width=4)
    draw.polygon([(tx, ty - tr + 14), (tx + tr - 12, ty + tr - 6), (tx - tr + 12, ty + tr - 6)], fill=(20, 22, 26, 255))
    draw.text((tx - 8, ty - 12), "!", fill=(235, 175, 25, 255), font=font_huge)


    # =========================================================================
    # ZONE 8: Utility Pole Signs & High Voltage Box (1440, 1020) -> (2028, 1600)
    # =========================================================================
    px0, py0, px1, py1 = 1440, 1020, 2028, 1600
    draw.rectangle([px0, py0, px1, py1], fill=(38, 42, 48, 255), outline=(18, 20, 24, 255), width=4)

    # Street Name Sign: "ASHFORD AVE"
    s1_x0, s1_y0, s1_x1, s1_y1 = px0 + 25, py0 + 25, px1 - 25, py0 + 125
    draw.rectangle([s1_x0, s1_y0, s1_x1, s1_y1], fill=(18, 85, 45, 255), outline=(245, 248, 255, 255), width=6)
    draw.text((s1_x0 + 40, s1_y0 + 18), "ASHFORD AVE", fill=(245, 248, 255, 255), font=font_giant)

    # Street Name Sign: "DISTRICT 13"
    s2_x0, s2_y0, s2_x1, s2_y1 = px0 + 25, py0 + 145, px1 - 160, py0 + 235
    draw.rectangle([s2_x0, s2_y0, s2_x1, s2_y1], fill=(18, 85, 45, 255), outline=(245, 248, 255, 255), width=5)
    draw.text((s2_x0 + 30, s2_y0 + 18), "DISTRICT 13", fill=(245, 248, 255, 255), font=font_huge)

    # High Voltage Junction Box FB-HV-04
    hvx0, hvy0, hvx1, hvy1 = px0 + 25, py0 + 260, px1 - 25, py1 - 25
    draw.rectangle([hvx0, hvy0, hvx1, hvy1], fill=(90, 95, 105, 255), outline=(20, 22, 26, 255), width=6)
    draw.rectangle([hvx0 + 12, hvy0 + 12, hvx1 - 12, hvy1 - 12], outline=(32, 35, 42, 255), width=3)
    draw.text((hvx0 + 35, hvy0 + 25), "FB-HV-04", fill=(240, 245, 255, 255), font=font_giant)
    draw.text((hvx0 + 35, hvy0 + 105), "HIGH VOLTAGE // 12.4 kV", fill=(235, 55, 40, 255), font=font_med)

    # Hazard lightning bolt
    ltx, lty, ltr = hvx0 + 115, hvy0 + 200, 52
    draw.polygon([(ltx, lty - ltr), (ltx + ltr, lty + ltr), (ltx - ltr, lty + ltr)], fill=(235, 180, 25, 255), outline=(20, 20, 24, 255), width=4)
    draw.polygon([(ltx - 6, lty - 28), (ltx + 15, lty - 28), (ltx - 2, lty + 2), (ltx + 18, lty + 2), (ltx - 12, lty + 35), (ltx - 2, lty + 10), (ltx - 16, lty + 10)], fill=(20, 22, 26, 255))


    # =========================================================================
    # ZONE 9: Environmental Shading Atlas (0, 1620) -> (2048, 2048)
    # =========================================================================
    # Sub-quadrant 1: WEATHERED SOOT TERRACOTTA BRICK MASONRY (0, 1620) -> (680, 2048)
    brick_colors = [
        (76, 42, 34, 255),
        (82, 46, 38, 255),
        (68, 38, 30, 255),
        (74, 40, 32, 255),
        (62, 35, 28, 255)
    ]
    draw.rectangle([0, 1620, 680, 2048], fill=(24, 22, 20, 255)) # Dark charcoal mortar background
    for by in range(1620, 2048, 20):
        r_idx = (by - 1620) // 20
        x_off = 26 if (r_idx % 2 == 1) else 0
        for bx in range(x_off - 52, 680, 52):
            b_col = random.choice(brick_colors)
            draw.rectangle([bx + 2, by + 2, bx + 50, by + 18], fill=b_col)

    # Sub-quadrant 2: Corrugated Industrial Metal (680, 1620) -> (1360, 2048)
    draw.rectangle([680, 1620, 1360, 2048], fill=(80, 85, 95, 255))
    for cx in range(680, 1360, 16):
        draw.rectangle([cx, 1620, cx + 10, 2048], fill=(125, 132, 142, 255))
        draw.rectangle([cx + 10, 1620, cx + 16, 2048], fill=(45, 48, 55, 255))

    # Sub-quadrant 3: Scrap Metal Shards (1360, 1620) -> (1700, 2048)
    draw.rectangle([1360, 1620, 1700, 2048], fill=(28, 30, 36, 255))
    cols = [(190, 145, 35), (145, 150, 160), (85, 95, 105), (185, 65, 35), (215, 165, 45)]
    for _ in range(70):
        sx0 = random.randint(1370, 1675)
        sy0 = random.randint(1630, 2025)
        sw = random.randint(18, 55)
        sh = random.randint(8, 24)
        col = random.choice(cols)
        draw.rectangle([sx0, sy0, sx0 + sw, sy0 + sh], fill=tuple(col) + (255,), outline=(15, 16, 20, 255), width=2)

    # Sub-quadrant 4: Road Stencil Decal "GD-13" (1700, 1620) -> (2048, 2048)
    draw.rectangle([1700, 1620, 2048, 2048], fill=(30, 32, 36, 255))
    draw.text((1720, 1640), "GEARS DISTRICT", fill=(240, 185, 25, 255), font=font_huge)
    draw.text((1720, 1715), "GD - 13", fill=(240, 185, 25, 255), font=font_giant)
    # Stencil hazard chevrons pointing along lane
    for cy in range(1815, 2030, 48):
        draw.polygon([
            (1730, cy),
            (1860, cy + 22),
            (1730, cy + 44),
            (1710, cy + 44),
            (1840, cy + 22),
            (1710, cy)
        ], fill=(240, 185, 25, 255))

    # =========================================================================
    # DEDICATED MATERIAL PALETTE SWATCHES (2000, 0) -> (2048, 400)
    # =========================================================================
    draw.rectangle([2000, 0, 2048, 50], fill=(72, 78, 88, 255))       # dark_metal (industrial gunmetal steel)
    draw.rectangle([2000, 50, 2048, 100], fill=(110, 118, 130, 255))  # structural_steel (bright angle-iron steel)
    draw.rectangle([2000, 100, 2048, 150], fill=(235, 175, 25, 255))  # yellow_accent (machinery yellow)
    draw.rectangle([2000, 150, 2048, 200], fill=(255, 220, 120, 255)) # warm_light (worklight amber)
    draw.rectangle([2000, 200, 2048, 250], fill=(48, 50, 54, 255))    # tar_roof (weathered tar gravel roof)
    draw.rectangle([2000, 250, 2048, 300], fill=(138, 142, 148, 255)) # concrete_curb (municipal curb concrete)
    draw.rectangle([2000, 300, 2048, 350], fill=(76, 42, 34, 255))    # terracotta_brick (dark soot masonry)
    draw.rectangle([2000, 350, 2048, 400], fill=(24, 25, 28, 255))    # contact_shadow (dark ink occlusion)
    draw.rectangle([2000, 400, 2048, 440], fill=(185, 35, 25, 255))   # red_tool_cabinet (automotive rolling chest red)
    draw.rectangle([2000, 440, 2048, 480], fill=(195, 188, 172, 255)) # weathered_cream (industrial painted concrete facade)

    out_tex_path = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter/tex_storefront_burnside.png"
    os.makedirs(os.path.dirname(out_tex_path), exist_ok=True)
    atlas.save(out_tex_path, format="PNG")
    print(f"Generated 2048x2048 Storefront Texture Atlas:\n  {out_tex_path}")

if __name__ == '__main__':
    main()
