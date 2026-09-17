from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# 1. Fascia sign: Panel B (1243, 214, 1637, 296)
fascia = sheet.crop((1243, 214, 1637, 296))
fascia.save("docs/visual_direction/references/crops/exact_fascia.png")

# 2. Billboard text: Panel E (371, 774, 607, 882)
billboard_text = sheet.crop((371, 774, 607, 882))
billboard_text.save("docs/visual_direction/references/crops/exact_billboard_text.png")

# 3. Billboard mascot: Panel A (566, 54, 714, 212)
billboard_mascot = sheet.crop((566, 54, 714, 212))
billboard_mascot.save("docs/visual_direction/references/crops/exact_billboard_mascot.png")

# 4. Garage shutter door: Panel B (1308, 324, 1494, 442)
shutter = sheet.crop((1308, 324, 1494, 442))
shutter.save("docs/visual_direction/references/crops/exact_shutter.png")

# 5. Service door: Panel B (1506, 355, 1582, 442)
service_door = sheet.crop((1506, 355, 1582, 442))
service_door.save("docs/visual_direction/references/crops/exact_service_door.png")

# 6. Side wall stencil: Panel C (1260, 510, 1380, 650)
side_stencil = sheet.crop((1260, 510, 1380, 650))
side_stencil.save("docs/visual_direction/references/crops/exact_side_stencil.png")

# 7. Side wall brick background: Panel C (1380, 530, 1580, 710)
side_brick = sheet.crop((1380, 530, 1580, 710))
side_brick.save("docs/visual_direction/references/crops/exact_side_brick.png")

# 8. Quota kiosk HUD screen: Panel F (636, 816, 792, 895)
kiosk_screen = sheet.crop((636, 816, 792, 895))
kiosk_screen.save("docs/visual_direction/references/crops/exact_kiosk.png")

# 9. Dumpster face: Panel G (816, 816, 1000, 898)
dumpster_face = sheet.crop((816, 816, 1000, 898))
dumpster_face.save("docs/visual_direction/references/crops/exact_dumpster.png")

# 10. Utility pole signs: Panel A (190, 350, 310, 480)
pole_signs = sheet.crop((190, 350, 310, 480))
pole_signs.save("docs/visual_direction/references/crops/exact_pole_signs.png")

print("All exact components extracted!")
