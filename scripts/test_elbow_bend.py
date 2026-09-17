import bpy
import math
from mathutils import Vector, Euler

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

# Let's inspect how pb_la and pb_ua move the hand in Blender
pb_ua = arm.pose.bones["UpperArm.L"]
pb_la = arm.pose.bones["LowerArm.L"]
pb_h  = arm.pose.bones["Hand.L"]
pb_i2 = arm.pose.bones["Index2.L"]

BASE = {
    "Hips": (-6.0, 0.0, 0.0), "Abdomen": (-4.0, 0.0, 0.0),
    "Torso": (-3.0, 0.0, 0.0), "Chest": (-2.0, 0.0, 0.0),
    "Neck": (0.0, 0.0, 0.0), "Head": (15.0, 0.0, 0.0),
}
for b, r in BASE.items():
    arm.pose.bones[b].rotation_quaternion = Euler(tuple(map(math.radians, r)), 'XYZ').to_quaternion()

# Current base rotations for L
base_ua = [-70.5, -25.4, -24.1]
base_la = [0.0, 58.2, -27.2]
base_h  = [16.1, 20.4, 12.4]

def get_i2(ua, la, h):
    pb_ua.rotation_quaternion = Euler(tuple(map(math.radians, ua)), 'XYZ').to_quaternion()
    pb_la.rotation_quaternion = Euler(tuple(map(math.radians, la)), 'XYZ').to_quaternion()
    pb_h.rotation_quaternion  = Euler(tuple(map(math.radians, h)), 'XYZ').to_quaternion()
    bpy.context.view_layer.update()
    # In Blender armature space:
    return pb_i2.head.copy(), pb_h.head.copy()

cur_i2, cur_h = get_i2(base_ua, base_la, base_h)
print("Current Index2.L in Blender armature space:", cur_i2)
print("Current Hand.L in Blender armature space:  ", cur_h)

# We need:
# Move Index2.L in Blender:
# To move back towards driver in Godot (+Z):
# In Godot, Z increased by +0.134m.
# In Godot, Y increased by +0.078m.
# In Godot, X changed by -0.017m.

# Test Jacobian of UpperArm and LowerArm in Blender armature space:
print("\n--- DELTAS ON INDEX2 IN BLENDER SPACE ---")
for axis in [0, 1, 2]:
    ua = list(base_ua)
    ua[axis] += 10.0
    p, _ = get_i2(ua, base_la, base_h)
    d = p - cur_i2
    print(f"UpperArm +10 deg on axis {axis}: dx={d.x:+.4f}, dy={d.y:+.4f}, dz={d.z:+.4f}")

for axis in [1, 2]:
    la = list(base_la)
    la[axis] += 10.0
    p, _ = get_i2(base_ua, la, base_h)
    d = p - cur_i2
    print(f"LowerArm +10 deg on axis {axis}: dx={d.x:+.4f}, dy={d.y:+.4f}, dz={d.z:+.4f}")

for axis in [0, 1, 2]:
    h = list(base_h)
    h[axis] += 10.0
    p, _ = get_i2(base_ua, base_la, h)
    d = p - cur_i2
    print(f"Hand     +10 deg on axis {axis}: dx={d.x:+.4f}, dy={d.y:+.4f}, dz={d.z:+.4f}")

