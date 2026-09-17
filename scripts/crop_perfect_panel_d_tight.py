from PIL import Image

sheet = Image.open("docs/visual_direction/references/storefront_concept_sheet.png")

# In Panel D:
# Header is at y=798
# Sign frame:
# Top blue border: y=825
# Bottom blue border: y=916
# Left border: x=10
# Right border: x=355
fascia_tight = sheet.crop((10, 825, 355, 916))
fascia_tight.save("docs/visual_direction/references/crops/fascia_d_tight.png")
print("fascia_d_tight size:", fascia_tight.size)
