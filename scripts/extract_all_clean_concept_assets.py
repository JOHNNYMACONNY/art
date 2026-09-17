from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# 1. Fascia Signboard (tight crop of the sign face):
# In fascia_panel_b_clean (1240, 200, 1640, 310)
# Top frame is around y=212, bottom frame is around y=296, left is 1243, right is 1636
fascia_face = sheet.crop((1243, 214, 1637, 296))
fascia_face.save("docs/visual_direction/references/crops/asset_fascia_sign.png")

# 2. Garage Shutter Door:
shutter_face = sheet.crop((1308, 324, 1494, 442))
shutter_face.save("docs/visual_direction/references/crops/asset_garage_shutter.png")

# 3. Service Door:
service_face = sheet.crop((1506, 355, 1582, 442))
service_face.save("docs/visual_direction/references/crops/asset_service_door.png")

# 4. Brick wall with stencil from Panel C:
# Panel C is y=485..730
brick_stencil = sheet.crop((1266, 560, 1460, 715))
brick_stencil.save("docs/visual_direction/references/crops/asset_brick_stencil.png")

# 5. Signal Quota Kiosk from Panel F (bottom row):
# Header is at y=802. Screen & housing:
kiosk_face = sheet.crop((636, 816, 792, 946))
kiosk_face.save("docs/visual_direction/references/crops/asset_quota_kiosk.png")

# 6. Scrap Dumpster from Panel G (bottom row):
dumpster_face = sheet.crop((816, 816, 1000, 946))
dumpster_face.save("docs/visual_direction/references/crops/asset_dumpster.png")

# 7. Street Grate / Decal from main scene or kiosk area:
# In main scene street: "GEARS DISTRICT GD-13" stencil and manhole cover!
# Let's crop x=500..850, y=690..780
street_decal = sheet.crop((500, 690, 850, 780))
street_decal.save("docs/visual_direction/references/crops/asset_street_decal.png")

print("All concept assets extracted!")
