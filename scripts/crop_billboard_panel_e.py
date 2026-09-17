from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Let's crop x=360..615, y=780..935
c = sheet.crop((365, 785, 610, 930))
c.save("docs/visual_direction/references/crops/billboard_e_test.png")

# And in Panel A (top left), the billboard is at:
# x=340..580, y=10..250
c_a = sheet.crop((335, 10, 580, 255))
c_a.save("docs/visual_direction/references/crops/billboard_a_perspective.png")

print("Cropped:", c.size, c_a.size)
