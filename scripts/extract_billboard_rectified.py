import cv2
import numpy as np

img = cv2.imread("docs/visual_direction/references/storefront_concept_sheet.png")

# In crop_billboard_corners: crop was ((550, 40) to (900, 380))
# Let's find 4 corners in full image coordinates (x, y):
# Top-Left corner of billboard face: (572, 74)
# Top-Right corner of billboard face: (872, 362) -- wait, let's look at the angle!
# In Panel A:
# Top edge runs from left to right, going DOWN and RIGHT:
# Actually:
# Billboard is viewed from top-down / elevated 32 deg angle!
# Top-left corner of white face:
# Left edge is nearly vertical or slightly tilted:
# Let's write a small script to find the white face polygon.
