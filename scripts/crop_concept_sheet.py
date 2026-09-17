from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")
w, h = sheet.size

# Let's crop several candidate regions:
# Top left (main 32 deg view): ~0..900, 0..550
# Top right / bottom right / etc.
crops = {
    "crop_main_perspective": (0, 0, int(w * 0.6), int(h * 0.6)),
    "crop_side_elevation": (int(w * 0.6), 0, w, int(h * 0.5)),
    "crop_garage_bay": (0, int(h * 0.55), int(w * 0.4), h),
    "crop_fascia_sign": (int(w * 0.38), int(h * 0.6), int(w * 0.72), int(h * 0.85)),
    "crop_billboard": (int(w * 0.68), int(h * 0.55), w, int(h * 0.85)),
    "crop_props_bottom": (int(w * 0.38), int(h * 0.8), w, h),
}

for name, box in crops.items():
    c = sheet.crop(box)
    c.save(f"docs/visual_direction/references/crops/{name}.png")
    print(f"{name}: {c.size}")

