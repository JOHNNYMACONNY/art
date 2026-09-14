from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Let's crop from y=750 to y=940
real_e = sheet.crop((365, 755, 610, 890))
real_e.save("docs/visual_direction/references/crops/real_panel_e.png")
print("real_e size:", real_e.size)
