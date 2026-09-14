import bpy
import math
import sys
from mathutils import Euler

# Test script to find exact rotations for Hand.L and Hand.R
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

# Clean actions
for act in list(bpy.data.actions):
    if 'car_' in act.name:
        bpy.data.actions.remove(act)

if arm.animation_data:
    for tr in list(arm.animation_data.nla_tracks):
        arm.animation_data.nla_tracks.remove(tr)

# We want to test different Hand.L rotations
h_x = float(sys.argv[-3]) if len(sys.argv) > 3 else 10.0
h_y = float(sys.argv[-2]) if len(sys.argv) > 2 else 30.0
h_z = float(sys.argv[-1]) if len(sys.argv) > 1 else 15.0

print(f"Testing Hand.L: ({h_x}, {h_y}, {h_z})")

# Modify add_car_drive_anim logic on the action
# Let us run it as a quick test
