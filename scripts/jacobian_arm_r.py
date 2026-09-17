import bpy
import math
from mathutils import Vector, Euler, Quaternion

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

def blender_to_godot(v):
    return Vector((-0.36 - v.x, -0.33 + v.z, 0.13 + v.y))

BASE_POSTURE = {
    "Hips":       (-6.0, 0.0, 0.0),
    "Abdomen":    (-4.0, 0.0, 0.0),
    "Torso":      (-3.0, 0.0, 0.0),
    "Chest":      (-2.0, 0.0, 0.0),
    "Neck":       (0.0, 0.0, 0.0),
    "Head":       (15.0, 0.0, 0.0),
}

for bname, (rx, ry, rz) in BASE_POSTURE.items():
    pb = arm.pose.bones.get(bname)
    if pb:
        pb.rotation_quaternion = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), 'XYZ').to_quaternion()

pb_ua = arm.pose.bones.get("UpperArm.R")
pb_la = arm.pose.bones.get("LowerArm.R")
pb_h  = arm.pose.bones.get("Hand.R")
pb_i2 = arm.pose.bones.get("Index2.R")

base_ua = [-72.0, 25.2, 23.0]
base_la = [0.0, -27.9, 50.9]
base_h  = [-25.4, -47.0, -31.4]

def set_pose(ua, la, h):
    pb_ua.rotation_quaternion = Euler((math.radians(ua[0]), math.radians(ua[1]), math.radians(ua[2])), 'XYZ').to_quaternion()
    pb_la.rotation_quaternion = Euler((0.0, math.radians(la[1]), math.radians(la[2])), 'XYZ').to_quaternion()
    pb_h.rotation_quaternion  = Euler((math.radians(h[0]), math.radians(h[1]), math.radians(h[2])), 'XYZ').to_quaternion()
    bpy.context.view_layer.update()
    return blender_to_godot(arm.matrix_world @ pb_i2.head)

base_pos = set_pose(base_ua, base_la, base_h)
print(f"Base Index2.R Godot: ({base_pos.x:+.4f}, {base_pos.y:+.4f}, {base_pos.z:+.4f})")
print("Target:            (-0.2171, +0.8648, -0.3849)")
print(f"Needed delta:      ({-0.2171 - base_pos.x:+.4f}, {0.8648 - base_pos.y:+.4f}, {-0.3849 - base_pos.z:+.4f})")

print("\n--- JACOBIAN OF INDEX2.R FOR R ARM (+5 deg) ---")
# UpperArm
for i, axis in enumerate(['X', 'Y', 'Z']):
    u = list(base_ua)
    u[i] += 5.0
    p = set_pose(u, base_la, base_h)
    d = p - base_pos
    print(f"UpperArm.R +5 {axis}: dx={d.x*100:+.2f}cm, dy={d.y*100:+.2f}cm, dz={d.z*100:+.2f}cm")

# LowerArm
for i, axis in [(1, 'Y'), (2, 'Z')]:
    l = list(base_la)
    l[i] += 5.0
    p = set_pose(base_ua, l, base_h)
    d = p - base_pos
    print(f"LowerArm.R +5 {axis}: dx={d.x*100:+.2f}cm, dy={d.y*100:+.2f}cm, dz={d.z*100:+.2f}cm")

# Hand
for i, axis in enumerate(['X', 'Y', 'Z']):
    h = list(base_h)
    h[i] += 5.0
    p = set_pose(base_ua, base_la, h)
    d = p - base_pos
    print(f"Hand.R     +5 {axis}: dx={d.x*100:+.2f}cm, dy={d.y*100:+.2f}cm, dz={d.z*100:+.2f}cm")

