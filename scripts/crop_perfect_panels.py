from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Let's get exact bounding boxes:
# D: Fascia signboard in bottom panel D
# The header "D FASCIA SIGN DETAIL" is around y=798.
# The signboard itself starts around y=825, ends around y=948
# Let's inspect x range:
box_d_exact = (10, 825, 360, 946)

# E: Billboard in bottom panel E
# Starts around x=365, y=815, ends around x=610, y=945
# Wait, let's look higher up for panel E: where is the mascot?
# In Panel A (top left), the billboard has the mascot!
# Where is the full billboard in Panel E?
# Let's crop x=360..615, y=790..950
box_e_full = (365, 795, 615, 955)

# Also in Panel B (top right FRONT ELEVATION), the fascia sign is fully shown straight-on!
# Let's crop Panel B's fascia signboard:
# Panel B is x=1220..1660, y=260..670
box_b_fascia = (1235, 335, 1650, 480)

crops = {
    "fascia_panel_d": (10, 820, 360, 948),
    "billboard_panel_e": (366, 800, 612, 950),
    "fascia_panel_b": (1238, 336, 1645, 475),
    "garage_panel_b": (1310, 485, 1495, 665),
    "service_panel_b": (1508, 520, 1582, 665),
    "brick_side_c": (1255, 715, 1465, 925),
    "quota_kiosk_f": (625, 805, 802, 950),
    "dumpster_g": (810, 805, 1005, 950),
    "pole_h": (1010, 805, 1205, 950),
}

for k, b in crops.items():
    c = sheet.crop(b)
    c.save(f"docs/visual_direction/references/crops/{k}.png")
    print(k, c.size)

