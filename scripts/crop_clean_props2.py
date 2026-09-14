from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Dumpster face: y ends around 900
dumpster_clean = sheet.crop((816, 816, 1000, 898))
dumpster_clean.save("docs/visual_direction/references/crops/asset_dumpster_clean.png")

# Quota Kiosk: y ends around 895
kiosk_clean = sheet.crop((636, 816, 792, 895))
kiosk_clean.save("docs/visual_direction/references/crops/asset_kiosk_clean.png")

print("Saved clean dumpster and kiosk without color swatches")
