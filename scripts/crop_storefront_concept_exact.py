from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Coordinates in 1672x941 sheet:
# D: FASCIA SIGN DETAIL (bottom-left)
# Box header around x=5..230, y=795..815
# The sign itself is inside the frame:
box_d = (7, 815, 360, 942)

# E: BILLBOARD DETAIL
box_e = (368, 815, 608, 945)

# F: QUOTA TERMINAL DETAIL
box_f = (628, 810, 804, 948)

# G: DUMPSTER / SCRAP DETAIL
box_g = (811, 810, 1007, 950)

# H: UTILITY POLE DETAIL
box_h = (1014, 810, 1205, 950)

# In Panel B (FRONT ELEVATION):
# Garage shutter door:
# Let's inspect coordinates in Panel B
# Panel B is roughly x=1220..1660, y=260..670
box_garage_door_b = (1270, 480, 1500, 670)
box_service_door_b = (1505, 505, 1585, 670)

# In Panel C (RIGHT ELEVATION):
# Panel C is roughly x=1220..1660, y=690..930
box_side_brick_c = (1260, 715, 1475, 930)

crops = {
    "panel_d_fascia": box_d,
    "panel_e_billboard": box_e,
    "panel_f_quota_kiosk": box_f,
    "panel_g_dumpster": box_g,
    "panel_h_utility_pole": box_h,
    "panel_b_garage_door": box_garage_door_b,
    "panel_b_service_door": box_service_door_b,
    "panel_c_side_elevation": box_side_brick_c
}

for name, box in crops.items():
    c = sheet.crop(box)
    c.save(f"docs/visual_direction/references/crops/{name}.png")
    print(f"Saved {name}: {c.size}")

