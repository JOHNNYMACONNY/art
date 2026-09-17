#!/usr/bin/env python3
"""
scripts/test_build_tactical_hand.py
Builds a clean, anatomically proportioned, game-ready tactical glove hand in Blender.
Designed to match CharacterArmature bone anatomy and docs/visual_direction/references/hand_blender_model_sheet.jpg.
"""

import bpy
import bmesh
from mathutils import Vector, Matrix, Quaternion, Euler
import math

def create_tactical_hand(side='L', debug_scene=True):
    if debug_scene:
        bpy.ops.wm.read_factory_settings(use_empty=True)

    is_left = (side == 'L')
    sign_x = 1.0 if is_left else -1.0

    bm = bmesh.new()

    # Bone landmarks (for Left Hand in runner.blend)
    # Hand.L:     head=(0.5678, -0.0855, 1.4321), tail=(0.7083, -0.0872, 1.4329)
    # Index2.L:   head=(0.7168, -0.1156, 1.4321), tail=(0.7490, -0.1186, 1.4375)
    # Middle2.L:  head=(0.7194, -0.0886, 1.4419), tail=(0.7596, -0.0885, 1.4457)
    # Ring2.L:    head=(0.7160, -0.0613, 1.4370), tail=(0.7493, -0.0561, 1.4404)
    # Pinky2.L:   head=(0.7053, -0.0392, 1.4368), tail=(0.7307, -0.0320, 1.4395)
    # Thumb2.L:   head=(0.6479, -0.1460, 1.4090), tail=(0.6722, -0.1662, 1.4034)

    # Let's define the anatomical geometry in local hand space where:
    # Origin = Wrist (head of Hand bone)
    # +X = Finger direction (distal reach along arm)
    # +Y = Palmar / thumb-side direction
    # +Z = Dorsal direction (back of hand is +Z, palm is -Z)

    # Hand dimensions (in meters):
    # Wrist to knuckle length: ~0.14m
    # Palm width: ~0.085m
    # Palm thickness: ~0.028m at thenar, ~0.022m at knuckles
    # Finger lengths: Index=0.088m, Middle=0.105m, Ring=0.098m, Pinky=0.076m, Thumb=0.065m

    # Build 8-segment cylinders for fingers with 3 deformation loops at each knuckle
    # Let's inspect the exact deformation quality.
    print(f"Building tactical glove hand for side {side}...")

if __name__ == '__main__':
    create_tactical_hand('L', True)
