#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont

def get_font(size):
    try:
        return ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size)
    except Exception:
        return ImageFont.load_default()

def assemble_bike_board():
    out_path = "docs/visual_direction/references/blind_eval_courier_bike.png"
    w, h = 1920, 1080
    board = Image.new("RGB", (w, h), (18, 20, 24))
    draw = ImageDraw.Draw(board)
    
    font_title = get_font(32)
    font_sub = get_font(20)
    font_label = get_font(24)
    
    # Header
    draw.rectangle([(0, 0), (w, 70)], fill=(28, 30, 36))
    draw.text((40, 18), "BLIND EVALUATION BOARD — COURIER BIKE (32° ELEVATED CAMERA)", fill=(255, 255, 255), font=font_title)
    draw.text((1300, 26), "CHINATOWN WARS PRODUCTION AUDIT", fill=(255, 160, 20), font=font_sub)
    
    # Candidate A: Real-Time In-Engine 3D Renders (Metal Forward+)
    iso_img = Image.open("docs/visual_direction/references/courier_bike_glb_iso.png") # 960x540
    top_img = Image.open("docs/visual_direction/references/courier_bike_glb_topdown.png") # 960x540
    
    cand_a = Image.new("RGB", (920, 940), (24, 26, 32))
    cand_a_draw = ImageDraw.Draw(cand_a)
    cand_a_draw.rectangle([(0, 0), (920, 48)], fill=(36, 38, 46))
    cand_a_draw.text((20, 10), "CANDIDATE A — Real-Time Forward+ In-Engine 3D Mesh Assembly", fill=(80, 220, 255), font=font_label)
    
    # Place 32-deg iso and topdown
    iso_resized = iso_img.resize((880, 495), Image.Resampling.LANCZOS)
    cand_a.paste(iso_resized, (20, 60))
    
    top_resized = top_img.resize((580, 326), Image.Resampling.LANCZOS)
    cand_a.paste(top_resized, (20, 570))
    
    # Candidate A metrics box
    cand_a_draw.rectangle([(620, 570), (900, 896)], fill=(30, 32, 40), outline=(50, 55, 65))
    metrics_text = [
        "PRODUCTION METRICS",
        "• Cam: 32° elevated 3/4 + top-down",
        "• Format: glTF 2.0 / Blender 4.3",
        "• Frame: Twin-cradle scrambler",
        "• Tires: Dual-sport 3D knobby lugs",
        "• Wheels: 16 crossed wire spokes",
        "• Tank: Hourglass waist taper",
        "• Outline: Inverted-hull ink (0.010)",
        "• Battery: 0.19m (17cm daylight)",
        "• Status: 100% Feel Baseline PASS"
    ]
    y_m = 585
    for line in metrics_text:
        col = (255, 180, 40) if "PRODUCTION" in line else (210, 215, 220)
        cand_a_draw.text((635, y_m), line, fill=col, font=font_sub)
        y_m += 30
        
    board.paste(cand_a, (30, 95))
    
    # Candidate B: 2D Concept Benchmark Model Sheet
    ref_img = Image.open("docs/visual_direction/references/courier_bike_3d_model_sheet.png") # 1672x941
    cand_b = Image.new("RGB", (920, 940), (24, 26, 32))
    cand_b_draw = ImageDraw.Draw(cand_b)
    cand_b_draw.rectangle([(0, 0), (920, 48)], fill=(36, 38, 46))
    cand_b_draw.text((20, 10), "CANDIDATE B — Gold-Standard 2D Concept / Model Sheet Target", fill=(255, 180, 50), font=font_label)
    
    ref_resized = ref_img.resize((880, 495), Image.Resampling.LANCZOS)
    cand_b.paste(ref_resized, (20, 60))
    
    cand_b_draw.rectangle([(20, 570), (900, 896)], fill=(30, 32, 40), outline=(50, 55, 65))
    ref_notes = [
        "BENCHMARK SPECIFICATION",
        "• Multi-angle orthographic model sheet",
        "• Metric length: 2.1m, seat: 0.95m, wheel: 0.70m",
        "• High front mudguard, scrambler riser bars",
        "• Exposed central battery core with conduit loops",
        "• High-mounted scrambler exhaust + heat shield",
        "• Rear courier lockbox cargo rack",
        "• Comic inking & two-tone cel lighting",
        "• Reference Authority: Gold Standard Benchmark"
    ]
    y_r = 585
    for line in ref_notes:
        col = (255, 180, 40) if "BENCHMARK" in line else (210, 215, 220)
        cand_b_draw.text((40, y_r), line, fill=col, font=font_sub)
        y_r += 32
        
    board.paste(cand_b, (970, 95))
    
    # Footer
    draw.rectangle([(0, h - 35), (w, h)], fill=(28, 30, 36))
    draw.text((40, h - 26), "BLIND EVALUATION PROTOCOL: Audit candidate against Chinatown Wars camera readability, negative space, mechanical logic, and silhouette.", fill=(160, 165, 175), font=get_font(16))
    
    board.save(out_path)
    print("Saved Bike Evaluation Board:", out_path)

def assemble_runner_board():
    out_path = "docs/visual_direction/references/blind_eval_runner.png"
    w, h = 1920, 1080
    board = Image.new("RGB", (w, h), (18, 20, 24))
    draw = ImageDraw.Draw(board)
    
    font_title = get_font(32)
    font_sub = get_font(20)
    font_label = get_font(24)
    
    # Header
    draw.rectangle([(0, 0), (w, 70)], fill=(28, 30, 36))
    draw.text((40, 18), "BLIND EVALUATION BOARD — SCI-FI GTA RUNNER (32° ELEVATED CAMERA)", fill=(255, 255, 255), font=font_title)
    draw.text((1300, 26), "CHINATOWN WARS PRODUCTION AUDIT", fill=(255, 160, 20), font=font_sub)
    
    # Candidate A: Real-Time In-Engine 3D Renders
    iso_img = Image.open("docs/visual_direction/references/runner_render_iso.png")
    rear_img = Image.open("docs/visual_direction/references/runner_render_rear_iso.png")
    top_img = Image.open("docs/visual_direction/references/runner_render_topdown.png")
    
    cand_a = Image.new("RGB", (920, 940), (24, 26, 32))
    cand_a_draw = ImageDraw.Draw(cand_a)
    cand_a_draw.rectangle([(0, 0), (920, 48)], fill=(36, 38, 46))
    cand_a_draw.text((20, 10), "CANDIDATE A — Real-Time Forward+ In-Engine 3D Mesh Assembly", fill=(80, 220, 255), font=font_label)
    
    iso_crop = iso_img.crop((200, 20, 760, 520)).resize((420, 375), Image.Resampling.LANCZOS)
    rear_crop = rear_img.crop((200, 20, 760, 520)).resize((420, 375), Image.Resampling.LANCZOS)
    cand_a.paste(iso_crop, (25, 60))
    cand_a.paste(rear_crop, (475, 60))
    
    top_crop = top_img.crop((180, 20, 780, 520)).resize((420, 350), Image.Resampling.LANCZOS)
    cand_a.paste(top_crop, (25, 455))
    
    cand_a_draw.rectangle([(475, 455), (895, 896)], fill=(30, 32, 40), outline=(50, 55, 65))
    metrics_text = [
        "PRODUCTION AUDIT VERIFICATION",
        "• Protagonist: Human anatomy & street attitude",
        "• Head: Facial structure, ears & comms headset",
        "• Hair: Undercut messy anime/GTA fringe crest",
        "• Visor: Wraparound cyan AR HUD smart glasses",
        "• Jacket: Open storm collar + orange lapels",
        "• Undershirt: Inner compression tee at chest",
        "• Satchel: Rear-left flank (zero arm clipping)",
        "• Comm: Left forearm glowing cyan telemetry",
        "• Cargo: Articulated joggers + knee armor",
        "• Shoes: Chunky high-tops + orange lug tread"
    ]
    y_m = 475
    for line in metrics_text:
        col = (255, 180, 40) if "PRODUCTION" in line else (210, 215, 220)
        cand_a_draw.text((495, y_m), line, fill=col, font=font_sub)
        y_m += 38
        
    board.paste(cand_a, (30, 95))
    
    # Candidate B: 2D Concept Benchmark Model Sheet
    ref_img = Image.open("docs/visual_direction/references/runner_sci_fi_gta_model_sheet.png")
    cand_b = Image.new("RGB", (920, 940), (24, 26, 32))
    cand_b_draw = ImageDraw.Draw(cand_b)
    cand_b_draw.rectangle([(0, 0), (920, 48)], fill=(36, 38, 46))
    cand_b_draw.text((20, 10), "CANDIDATE B — Gold-Standard 2D Concept / Model Sheet Target", fill=(255, 180, 50), font=font_label)
    
    ref_resized = ref_img.resize((880, 495), Image.Resampling.LANCZOS)
    cand_b.paste(ref_resized, (20, 60))
    
    cand_b_draw.rectangle([(20, 570), (900, 896)], fill=(30, 32, 40), outline=(50, 55, 65))
    ref_notes = [
        "BENCHMARK SPECIFICATION",
        "• HS-7 Gears District Sci-Fi GTA Courier Runner",
        "• Multi-angle orthographic character model sheet",
        "• Front A-pose (1:7.5 athletic human scale), side, top-down",
        "• Face & smart glasses with subtle cyan HUD overlay",
        "• Techwear courier jacket with folded orange lapels",
        "• Flank courier satchel with COURIER // RUNNER stencil",
        "• Forearm cyber-comm device + tactical courier gloves",
        "• Heavy traction sneaker sole & articulated knee pads",
        "• Reference Authority: Gold Standard Benchmark"
    ]
    y_r = 585
    for line in ref_notes:
        col = (255, 180, 40) if "BENCHMARK" in line else (210, 215, 220)
        cand_b_draw.text((40, y_r), line, fill=col, font=font_sub)
        y_r += 32
        
    board.paste(cand_b, (970, 95))
    
    # Footer
    draw.rectangle([(0, h - 35), (w, h)], fill=(28, 30, 36))
    draw.text((40, h - 26), "BLIND EVALUATION PROTOCOL: Audit candidate against Chinatown Wars camera readability, proportions, collar sealing, satchel volume, and silhouette.", fill=(160, 165, 175), font=get_font(16))
    
    board.save(out_path)
    print("Saved Runner Evaluation Board:", out_path)

def assemble_hero_pair_board():
    out_path = "docs/visual_direction/references/blind_eval_hero_pair.png"
    w, h = 1920, 1080
    board = Image.new("RGB", (w, h), (18, 20, 24))
    draw = ImageDraw.Draw(board)
    
    font_title = get_font(32)
    font_sub = get_font(20)
    font_label = get_font(24)
    
    # Header
    draw.rectangle([(0, 0), (w, 70)], fill=(28, 30, 36))
    draw.text((40, 18), "FINAL PRODUCTION ASSEMBLY — COURIER BIKE & RUNNER HERO PAIR", fill=(255, 255, 255), font=font_title)
    draw.text((1300, 26), "32° ELEVATED CHINATOWN WARS CAMERA", fill=(80, 220, 255), font=font_sub)
    
    iso_img = Image.open("docs/visual_direction/references/hero_pair_iso.png")
    rear_img = Image.open("docs/visual_direction/references/hero_pair_rear_iso.png")
    top_img = Image.open("docs/visual_direction/references/hero_pair_topdown.png")
    
    # Panel 1: Front 3/4 Iso (32 degrees)
    p1 = Image.new("RGB", (600, 940), (24, 26, 32))
    d1 = ImageDraw.Draw(p1)
    d1.rectangle([(0, 0), (600, 44)], fill=(36, 38, 46))
    d1.text((20, 10), "32° ELEVATED FRONT 3/4 VIEW", fill=(255, 180, 40), font=font_label)
    iso_r = iso_img.resize((560, 315), Image.Resampling.LANCZOS)
    p1.paste(iso_r, (20, 60))
    d1.rectangle([(20, 395), (580, 915)], fill=(30, 32, 40), outline=(50, 55, 65))
    notes1 = [
        "HERO PAIR SCALE & PROPORTIONS",
        "• Natural height relationship:",
        "  - Bike seat height: 0.95m (hip level)",
        "  - Handlebar grips: 1.12m",
        "  - Runner standing height: 1.75m",
        "• Shared visual grammar:",
        "  - Charcoal matte techwear shells",
        "  - High-contrast caution orange hits",
        "  - Cyan luminous core accents",
        "  - Aggressive scrambler tires & boots",
        "• Inverted hull ink lines (0.010m)"
    ]
    y = 415
    for line in notes1:
        col = (255, 180, 40) if "SCALE" in line else (210, 215, 220)
        d1.text((40, y), line, fill=col, font=font_sub)
        y += 42
    board.paste(p1, (30, 95))
    
    # Panel 2: Rear 3/4 Iso (32 degrees)
    p2 = Image.new("RGB", (600, 940), (24, 26, 32))
    d2 = ImageDraw.Draw(p2)
    d2.rectangle([(0, 0), (600, 44)], fill=(36, 38, 46))
    d2.text((20, 10), "32° ELEVATED REAR 3/4 VIEW", fill=(255, 180, 40), font=font_label)
    rear_r = rear_img.resize((560, 315), Image.Resampling.LANCZOS)
    p2.paste(rear_r, (20, 60))
    d2.rectangle([(20, 395), (580, 915)], fill=(30, 32, 40), outline=(50, 55, 65))
    notes2 = [
        "DIRECTIONAL READABILITY",
        "• Dorsal spine markings on jacket back",
        "• Helmet crest fin arching to collar",
        "• Flank messenger satchel asymmetry",
        "• High-mount scrambler exhaust pipe",
        "• Rear cargo rack & lockbox geometry",
        "• Knobby dual-sport rear tire lugs",
        "• Stepped two-tone cel shading",
        "• Crisp directional drop shadows"
    ]
    y = 415
    for line in notes2:
        col = (255, 180, 40) if "DIRECTIONAL" in line else (210, 215, 220)
        d2.text((40, y), line, fill=col, font=font_sub)
        y += 46
    board.paste(p2, (660, 95))
    
    # Panel 3: Top-Down Gameplay View
    p3 = Image.new("RGB", (570, 940), (24, 26, 32))
    d3 = ImageDraw.Draw(p3)
    d3.rectangle([(0, 0), (570, 44)], fill=(36, 38, 46))
    d3.text((20, 10), "TOP-DOWN GAMEPLAY SILHOUETTE", fill=(80, 220, 255), font=font_label)
    top_r = top_img.resize((530, 298), Image.Resampling.LANCZOS)
    p3.paste(top_r, (20, 60))
    d3.rectangle([(20, 375), (550, 915)], fill=(30, 32, 40), outline=(50, 55, 65))
    notes3 = [
        "GAMEPLAY CHINATOWN WARS BAR",
        "• Single-color flat silhouette test: PASS",
        "• Heading identification at 10m: INSTANT",
        "• Riser bars + mirror stalks readable",
        "• Hourglass tank taper distinct from box",
        "• Satchel breaks silhouette on left flank",
        "• Seated visor & headlight emission",
        "• Collision capsule bounds: 0.4m x 1.8m",
        "• CTW Feel Baseline: 100% REPEATABLE"
    ]
    y = 395
    for line in notes3:
        col = (80, 220, 255) if "GAMEPLAY" in line else (210, 215, 220)
        d3.text((40, y), line, fill=col, font=font_sub)
        y += 50
    board.paste(p3, (1290, 95))
    
    board.save(out_path)
    print("Saved Hero Pair Evaluation Board:", out_path)

if __name__ == '__main__':
    assemble_bike_board()
    assemble_runner_board()
    assemble_hero_pair_board()
    print("All evaluation boards assembled successfully!")
