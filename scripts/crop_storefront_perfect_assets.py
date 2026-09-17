from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# In Panel B, the top of the storefront is at y=170..480!
# Let's crop x=1220..1660, y=160..480
panel_b_top = sheet.crop((1220, 160, 1660, 480))
panel_b_top.save("docs/visual_direction/references/crops/panel_b_top.png")

# And the fascia signboard in Panel B:
# Around x=1240..1640, y=200..320
fascia_panel_b = sheet.crop((1240, 200, 1640, 310))
fascia_panel_b.save("docs/visual_direction/references/crops/fascia_panel_b_clean.png")

print("Saved panel_b_top and fascia_panel_b_clean")
