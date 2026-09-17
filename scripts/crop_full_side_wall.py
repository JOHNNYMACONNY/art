from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Look at Panel C (RIGHT ELEVATION):
# Full wall from left corner to right edge:
# x=1250..1640, y=500..660
side_wall_composite = sheet.crop((1250, 505, 1640, 665))
side_wall_composite.save("docs/visual_direction/references/crops/exact_side_wall_full.png")
print("exact_side_wall_full size:", side_wall_composite.size)
