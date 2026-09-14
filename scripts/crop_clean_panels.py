from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Let's inspect panel B in detail:
# Panel B is FRONT ELEVATION
# Let's crop Panel B completely:
panel_b = sheet.crop((1220, 260, 1660, 680))
panel_b.save("docs/visual_direction/references/crops/panel_b_full.png")

# Fascia sign inside Panel B:
# Let's crop just the sign face (excluding lights and outer wall):
# In Panel B, the sign is located horizontally and vertically:
fascia_b = sheet.crop((1245, 345, 1640, 442))
fascia_b.save("docs/visual_direction/references/crops/fascia_b_face.png")

# Shutter garage door inside Panel B:
shutter_b = sheet.crop((1308, 488, 1494, 663))
shutter_b.save("docs/visual_direction/references/crops/shutter_b_face.png")

# Service door inside Panel B:
service_b = sheet.crop((1506, 522, 1582, 663))
service_b.save("docs/visual_direction/references/crops/service_b_face.png")

# Let's inspect panel C in detail:
panel_c = sheet.crop((1220, 700, 1660, 940))
panel_c.save("docs/visual_direction/references/crops/panel_c_full.png")

# Brick wall with stencils inside Panel C:
brick_c = sheet.crop((1254, 735, 1465, 930))
brick_c.save("docs/visual_direction/references/crops/brick_c_wall.png")

print("Saved panel crops successfully!")
