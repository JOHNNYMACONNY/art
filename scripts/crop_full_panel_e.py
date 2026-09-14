from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Let's crop full Panel E:
# Panel E has header "E BILLBOARD DETAIL"
# Header is at y=800.
# The billboard starts right below header at y=815, and goes to y=948!
# Left edge is around x=366, right edge is around x=610
panel_e_full = sheet.crop((368, 815, 608, 946))
panel_e_full.save("docs/visual_direction/references/crops/panel_e_full.png")
print("panel_e_full size:", panel_e_full.size)
