from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# 1. Mascot from Main Scene (Panel A):
# In full sheet coordinates:
# x=560..670, y=50..220
mascot = sheet.crop((566, 68, 668, 205))
mascot.save("docs/visual_direction/references/crops/lung_renew_mascot.png")

# 2. Aero Inhaler & Text from Panel E:
# Panel E is x=366..608, y=810..945
panel_e = sheet.crop((368, 810, 608, 935))
panel_e.save("docs/visual_direction/references/crops/lung_renew_panel_e_clean.png")

print("Mascot size:", mascot.size)
print("Panel E size:", panel_e.size)
