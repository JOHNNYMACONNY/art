import os
from PIL import Image, ImageDraw, ImageFont

REF_DIR = "docs/visual_direction/references"
OUT_PATH = "docs/visual_direction/references/char_steering_composite_board.png"
ARTIFACT_PATH = "/Users/bobbyinthelobby/.gemini/antigravity/brain/9e9e065f-c163-4cfc-9c03-fd8f38857a04/char_steering_composite_board.png"

panels = [
    # Row 1: Muscle Coupe
    ("char_seated_coupe_32deg.png", "V8 COUPE // NEUTRAL DRIVE (10-AND-2)", "Curled phalanges clench wheel rim, -15° backrest recline"),
    ("char_steer_coupe_left.png", "V8 COUPE // LEFT LOCK TURN", "Counter-clockwise wheel turn: right arm pushes up, left pulls down"),
    ("char_steer_coupe_right.png", "V8 COUPE // RIGHT LOCK TURN", "Clockwise wheel turn: left arm pushes up, right pulls down"),
    ("char_seated_coupe_iso.png", "V8 COUPE // SIDE PROFILE COCKPIT", "Enclosed cockpit framing, zero windshield or dash clipping"),

    # Row 2: Security Interceptor
    ("char_seated_interceptor_32deg.png", "INTERCEPTOR // NEUTRAL DRIVE (10-AND-2)", "Tactical grip on steering rim, MDT console framing"),
    ("char_steer_interceptor_left.png", "INTERCEPTOR // LEFT LOCK TURN", "Apex lean (-4° roll), head turns into corner (+6° yaw)"),
    ("char_steer_interceptor_right.png", "INTERCEPTOR // RIGHT LOCK TURN", "Apex lean (+4° roll), dynamic arm crossover on wheel"),
    ("char_seated_interceptor_iso.png", "INTERCEPTOR // SIDE PROFILE COCKPIT", "Seated driver posture verified through unit door livery"),

    # Row 3: Scrap Hauler Heavy COE Truck
    ("char_seated_hauler_32deg.png", "SCRAP HAULER // LOWERED CAB SEAT", "Driver height lowered -1.18m; generous ceiling headroom"),
    ("char_steer_hauler_left.png", "SCRAP HAULER // HEAVY LEFT STEER", "Two-handed truck wheel control, right arm high"),
    ("char_steer_hauler_right.png", "SCRAP HAULER // HEAVY RIGHT STEER", "Two-handed truck wheel control, left arm high"),
    ("char_seated_hauler_iso.png", "SCRAP HAULER // CAB SIDE PROFILE", "Side window confirmation: head completely below roof beam"),
]

PANEL_W, PANEL_H = 600, 338
COLS, ROWS = 4, 3
HEADER_H = 95
FOOTER_H = 45
BOARD_W = PANEL_W * COLS + 40
BOARD_H = HEADER_H + (PANEL_H + 50) * ROWS + FOOTER_H

board = Image.new("RGB", (BOARD_W, BOARD_H), (16, 17, 21))
draw = ImageDraw.Draw(board)

try:
    font_title = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 26)
    font_sub = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 15)
    font_card_title = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 13)
    font_card_sub = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 11)
except Exception:
    font_title = ImageFont.load_default()
    font_sub = ImageFont.load_default()
    font_card_title = ImageFont.load_default()
    font_card_sub = ImageFont.load_default()

# Header
draw.rectangle([0, 0, BOARD_W, HEADER_H], fill=(10, 11, 14))
draw.line([0, HEADER_H - 1, BOARD_W, HEADER_H - 1], fill=(255, 106, 0), width=3)
draw.text((25, 18), "PROJECT GEARS // AUTOMOTIVE DRIVER STEERING & CABIN CLEARANCE BOARD", fill=(255, 255, 255), font=font_title)
draw.text((25, 54), "DYNAMIC POWER GRIP (CURLED FINGERS) + CROSSOVER STEERING BIOMECHANICS + LOWERED TRUCK ROOF CLEARANCE", fill=(255, 170, 60), font=font_sub)

for idx, (filename, label, note) in enumerate(panels):
    c = idx % COLS
    r = idx // COLS
    
    x = 20 + c * PANEL_W
    y = HEADER_H + 15 + r * (PANEL_H + 50)
    
    img_path = os.path.join(REF_DIR, filename)
    if os.path.exists(img_path):
        src = Image.open(img_path).resize((PANEL_W - 10, PANEL_H - 10), Image.Resampling.LANCZOS)
        board.paste(src, (x + 5, y + 5))
        draw.rectangle([x + 4, y + 4, x + PANEL_W - 5, y + PANEL_H - 5], outline=(50, 54, 65), width=1)
    
    bar_y = y + PANEL_H
    draw.rectangle([x + 5, bar_y, x + PANEL_W - 5, bar_y + 42], fill=(22, 24, 30))
    draw.text((x + 10, bar_y + 6), label, fill=(255, 255, 255), font=font_card_title)
    draw.text((x + 10, bar_y + 23), note, fill=(155, 165, 180), font=font_card_sub)

# Footer
draw.rectangle([0, BOARD_H - FOOTER_H, BOARD_W, BOARD_H], fill=(10, 11, 14))
draw.text((25, BOARD_H - 30), "PRODUCED VIA GODOT 4.7.1 FORWARD+ ENGINE // SKELETAL RIG BINDING VERIFIED: INDEX2-4, MIDDLE2-4, RING2-4, PINKY2-4, THUMB2-3", fill=(120, 130, 145), font=font_card_sub)

board.save(OUT_PATH)
board.save(ARTIFACT_PATH)
print("Saved steering composite board to:", OUT_PATH, "and", ARTIFACT_PATH)
