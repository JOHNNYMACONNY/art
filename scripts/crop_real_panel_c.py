from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Look at storefront_concept_sheet.png:
# Panel B is FRONT ELEVATION: y=160..450, x=1220..1660
# Panel C is RIGHT ELEVATION (SIDE): y=460..730, x=1220..1660!
# Panel I is KEY ASSETS: y=735..940!
c_full = sheet.crop((1220, 460, 1660, 730))
c_full.save("docs/visual_direction/references/crops/real_panel_c_full.png")

# Inside Panel C:
# Header "C RIGHT ELEVATION (SIDE)" is at y=460..490
# The building side wall itself is at:
# x=1250..1650, y=500..710!
c_wall = sheet.crop((1250, 520, 1640, 715))
c_wall.save("docs/visual_direction/references/crops/real_panel_c_wall.png")

# Stencil wall portion (the cream painted rectangular patch with text):
# In Panel C, on the left side of the wall:
# "SCRAP REBUILDS KEEPS CITIES ALIVE."
c_stencil = sheet.crop((1260, 560, 1375, 710))
c_stencil.save("docs/visual_direction/references/crops/real_panel_c_stencil.png")

print("Cropped real Panel C!")
