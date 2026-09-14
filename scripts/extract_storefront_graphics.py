import cv2
import numpy as np
from PIL import Image

# Read storefront concept sheet
sheet_cv = cv2.imread("docs/visual_direction/references/storefront_concept_sheet.png")

# 1. Perspective rectify Billboard from main scene:
# In test_billboard_search, let's identify the 4 corners of the billboard face:
# In full sheet coordinates:
# Top-left corner of billboard frame: around (570, 75)
# Top-right corner of billboard frame: around (875, 360) wait, let's find exact coordinates
