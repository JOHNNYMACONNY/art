from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# Let's search where the anime girl is:
# In the concept sheet, top left has "GEARS DISTRICT: STREET CORNER & STOREFRONTS"
# To the right of that header: x=340..580, y=10..240?
# Wait, let's crop x=330..600, y=0..250 and also x=550..900, y=0..250
c1 = sheet.crop((340, 10, 580, 250))
c2 = sheet.crop((560, 10, 800, 250))
c3 = sheet.crop((330, 20, 580, 250))

# Wait, let's look at the full concept sheet image we saw earlier!
# The billboard in the main scene was on the roof above Burnside sign!
# The roof billboard is around x=340..580, y=10..240? Wait, no! Look at the image we saw of storefront_concept_sheet.png:
# In the top left:
# Header: "GEARS DISTRICT"
# Below header: "A MAIN SCENE"
# Next to header: anime girl with green visor and "LUNG-RENEW 4.0: Breathe Easy with 15% Fewer Ads Per Inhale!"
# Wait, that's at the very top! Let's find its exact coordinates!
crops = {
    "top_billboard": (340, 10, 580, 250),
    "header_right": (330, 10, 600, 250),
}
sheet.crop((335, 12, 575, 245)).save("docs/visual_direction/references/crops/test_top_b.png")
