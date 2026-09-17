from PIL import Image

# 1. Dumpster: crop above bottom bar (y=816..915)
sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Dumpster face without bottom grey bar:
dumpster_clean = sheet.crop((816, 816, 1000, 915))
dumpster_clean.save("docs/visual_direction/references/crops/asset_dumpster_clean.png")

# Quota Kiosk without bottom grey bar:
kiosk_clean = sheet.crop((636, 816, 792, 915))
kiosk_clean.save("docs/visual_direction/references/crops/asset_kiosk_clean.png")

print("Cropped clean dumpster and kiosk!")
