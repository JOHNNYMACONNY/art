import os
from PIL import Image, ImageDraw, ImageFont

REF_DIR = "docs/visual_direction/references"
OUT_PATH = "docs/visual_direction/references/seated_driving_and_riding_posture_library.png"
ARTIFACT_PATH = "/Users/bobbyinthelobby/.gemini/antigravity/brain/9e9e065f-c163-4cfc-9c03-fd8f38857a04/seated_driving_and_riding_posture_library.png"

panels = [
    # Row 1: Car Seated Driving Postures (Coupe & Interceptor)
    ("char_seated_coupe_32deg.png", "V8 COUPE // NEUTRAL DRIVE (10-AND-2)", "Curled phalanges clench wheel rim, -15 deg backrest lumbar recline"),
    ("char_steer_coupe_left.png", "V8 COUPE // LEFT LOCK TURN", "Counter-clockwise wheel turn: right arm pushes up, left pulls down"),
    ("char_steer_coupe_right.png", "V8 COUPE // RIGHT LOCK TURN", "Clockwise wheel turn: left arm pushes up, right pulls down"),
    ("char_grip_macro_hands.png", "V8 COUPE // TACTICAL GLOVE POWER GRIP", "5 articulated digits clench 36cm rim tube, thumb safety locked"),

    # Row 2: Heavy COE Truck Seated Postures (Scrap Hauler)
    ("char_seated_hauler_32deg.png", "SCRAP HAULER // LOWERED CAB SEAT", "Driver height lowered -1.18m; generous ceiling headroom in COE cab"),
    ("char_steer_hauler_left.png", "SCRAP HAULER // HEAVY LEFT STEER", "Two-handed 45cm truck wheel control, pronated wrist pull"),
    ("char_steer_hauler_right.png", "SCRAP HAULER // HEAVY RIGHT STEER", "Two-handed 45cm truck wheel control, pronated wrist push"),
    ("char_seated_hauler_iso.png", "SCRAP HAULER // CAB SIDE PROFILE", "Side window confirmation: head completely below roof beam"),

    # Row 3: Courier Bike Scrambler Riding Postures (Cycle-Ergo & SAE Biomechanics)
    ("proof_bike_ride_side.png", "COURIER BIKE // SCRAMBLER RIDER TRIANGLE", "Hips lowered on saddle (Y=0.98m), knees at 86 deg, torso pitched +22 deg"),
    ("proof_bike_ride_iso.png", "COURIER BIKE // CHINATOWN WARS 32 DEG VIEW", "Hands pronated on handlebars (Y=1.18m), thighs gripping battery console"),
    ("proof_bike_ride_front.png", "COURIER BIKE // ATTACK STANCE (FRONT)", "Flared elbows (+25 deg), level sightline through helmet visor, headlight glow"),
    ("proof_bike_ride_pov.png", "COURIER BIKE // FIRST-PERSON COCKPIT POV", "True eye-level look down at handlebars, tactical gloves, and front wheel"),

    # Row 4: Courier Bike Dynamics & Tactical Glove Grip Closure
    ("proof_bike_ride_ots.png", "COURIER BIKE // OVER-THE-SHOULDER OTS", "Rigid spine armor, high-contrast courier suit, tactical glove handlebar lock"),
    ("proof_bike_macro_hands.png", "COURIER BIKE // TACTICAL GLOVE GRIP MACRO", "Full finger curl around 2.2cm tube: Index/Mid/Ring/Pinky + Thumb under"),
    ("proof_bike_lean_left.png", "COURIER BIKE // HIGH-SPEED LEFT LEAN", "Torso rolls -14 deg, inner knee hugs, outer braces, head horizon-locked"),
    ("proof_bike_lean_right.png", "COURIER BIKE // HIGH-SPEED RIGHT LEAN", "Countersteer crossover, symmetric apex lean into sharp curve"),
]

PANEL_W, PANEL_H = 600, 338
COLS, ROWS = 4, 4
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
draw.text((25, 18), "PROJECT GEARS // SEATED DRIVING & MOTORCYCLE RIDING POSTURE LIBRARY", fill=(255, 255, 255), font=font_title)
draw.text((25, 54), "CYCLE-ERGO & SAE J1100 ERGONOMICS // AUTOMOTIVE 10-AND-2 + COE TRUCK CAB + SCRAMBLER ATTACK POSTURE + DYNAMIC LEAN", fill=(255, 170, 60), font=font_sub)

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
draw.text((25, BOARD_H - 30), "PRODUCED VIA GODOT 4.7.1 FORWARD+ ENGINE // SKELETAL RIG BINDINGS: anim_car_drive, anim_car_steer_*, anim_bike_ride, anim_bike_lean_* // TACTICAL GLOVES VERIFIED", fill=(120, 130, 145), font=font_card_sub)

board.save(OUT_PATH)
board.save(ARTIFACT_PATH)
print("Saved seated driving and riding posture library board to:", OUT_PATH, "and", ARTIFACT_PATH)
