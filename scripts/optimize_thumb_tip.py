import bpy
import math
from mathutils import Vector, Euler

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

def b2g(v): return Vector((-0.36 - v.x, -0.33 + v.z, 0.13 + v.y))
wc = Vector((-0.36, 0.79, -0.35))
tilt = math.radians(-25.0)

def torus(p):
    d = p - wc
    dy = d.y * math.cos(-tilt) - d.z * math.sin(-tilt)
    dz = d.y * math.sin(-tilt) + d.z * math.cos(-tilt)
    r = math.sqrt(d.x**2 + dy**2)
    s = math.sqrt((r - 0.165)**2 + dz**2) - 0.015
    a = math.degrees(math.atan2(dy, d.x))
    if a < 0: a += 360.0
    return s * 100.0, a / 30.0

POSTURE = {
    "Hips":       (-6.0, 0.0, 0.0),
    "Abdomen":    (-4.0, 0.0, 0.0),
    "Torso":      (-3.0, 0.0, 0.0),
    "Chest":      (-2.0, 0.0, 0.0),
    "Neck":       (0.0, 0.0, 0.0),
    "Head":       (15.0, 0.0, 0.0),
    "UpperArm.L": (-70.5, -25.4, -24.1),
    "LowerArm.L": (0.0, 58.2, -27.2),
    "Hand.L":     (16.1, 20.4, 12.4),
    "UpperArm.R": (-66.0, 41.8, 34.2),
    "LowerArm.R": (0.0, -47.8, 6.2),
    "Hand.R":     (7.5, -19.0, -7.2),
}

for b, r in POSTURE.items():
    arm.pose.bones[b].rotation_quaternion = Euler(tuple(map(math.radians, r)), 'XYZ').to_quaternion()

for side in ["L", "R"]:
    pb_t2 = arm.pose.bones[f"Thumb2.{side}"]
    pb_t3 = arm.pose.bones[f"Thumb3.{side}"]

    best_s = 999.0
    best_rot = None
    for t2_x in range(-50, 50, 5):
        for t2_y in range(-90, 90, 10):
            for t2_z in range(-90, 90, 10):
                pb_t2.rotation_quaternion = Euler((math.radians(t2_x), math.radians(t2_y), math.radians(t2_z)), 'XYZ').to_quaternion()
                for t3_x in range(-70, 30, 10):
                    pb_t3.rotation_quaternion = Euler((math.radians(t3_x), 0, 0), 'XYZ').to_quaternion()
                    bpy.context.view_layer.update()

                    tip = b2g(arm.matrix_world @ pb_t3.tail)
                    s, c = torus(tip)
                    if abs(s) < best_s:
                        best_s = abs(s)
                        best_rot = ((t2_x, t2_y, t2_z), (t3_x, 0, 0), s, c, tip)

    print(f"\nBest Thumb for {side}:")
    print(f"  Thumb2.{side}: {best_rot[0]}")
    print(f"  Thumb3.{side}: {best_rot[1]}")
    print(f"  Thumb Tip Surf Dist: {best_rot[2]:.2f} cm (Clock: {best_rot[3]:.1f}h)")

