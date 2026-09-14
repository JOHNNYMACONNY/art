from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Let's see the full height of the side wall stencil:
# In Panel C:
# y=500..650, x=1260..1380
side_stencil_top = sheet.crop((1260, 510, 1380, 650))
side_stencil_top.save("docs/visual_direction/references/crops/side_stencil_top.png")

# And in Panel A (main 32 deg scene):
# The side brick wall stencil is at x=200..320, y=280..480:
# Let's crop it to check:
side_stencil_a = sheet.crop((190, 270, 310, 480))
side_stencil_a.save("docs/visual_direction/references/crops/side_stencil_a.png")

print("Cropped side stencils!")
