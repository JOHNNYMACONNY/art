from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Let's crop full mascot from Panel A:
# x=560..720, y=50..220
mascot_full = sheet.crop((564, 52, 715, 215))
mascot_full.save("docs/visual_direction/references/crops/mascot_full.png")

# And let's check panel E header:
# In Panel E, where did "LUNG-RENEW 4.0:" get cut off?
# Let's crop x=360..610, y=780..850
panel_e_head = sheet.crop((365, 780, 610, 850))
panel_e_head.save("docs/visual_direction/references/crops/panel_e_head.png")

print("Cropped full mascot and panel e head")
