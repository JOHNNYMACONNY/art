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

BASE = {
    "Hips": (-6.0, 0.0, 0.0), "Abdomen": (-4.0, 0.0, 0.0),
    "Torso": (-3.0, 0.0, 0.0), "Chest": (-2.0, 0.0, 0.0),
    "Neck": (0.0, 0.0, 0.0), "Head": (15.0, 0.0, 0.0),
}
for b, r in BASE.items():
    arm.pose.bones[b].rotation_quaternion = Euler(tuple(map(math.radians, r)), 'XYZ').to_quaternion()

target = Vector((-0.2171, 0.8648, -0.3849))
pb_ua = arm.pose.bones["UpperArm.R"]
pb_la = arm.pose.bones["LowerArm.R"]
pb_h  = arm.pose.bones["Hand.R"]
pb_i2 = arm.pose.bones["Index2.R"]

best_err = 999.0
best_cfg = None

for dua_z in [-3, -2, -1, 0, 1, 2, 3, 4, 5]:
    for dla_z in [-4, -2, 0, 2, 4]:
        for dla_y in [-4, -2, 0, 2, 4]:
            pb_ua.rotation_quaternion = Euler((math.radians(-66.0), math.radians(41.8), math.radians(34.2 + dua_z)), 'XYZ').to_quaternion()
            pb_la.rotation_quaternion = Euler((0.0, math.radians(-47.8 + dla_y), math.radians(4.2 + dla_z)), 'XYZ').to_quaternion()
            for dh_x in [-6, -3, 0, 3, 6, 9]:
                for dh_y in [-6, -3, 0, 3, 6]:
                    for dh_z in [-6, -3, 0, 3, 6]:
                        pb_h.rotation_quaternion = Euler((math.radians(13.5 + dh_x), math.radians(-25.0 + dh_y), math.radians(-7.2 + dh_z)), 'XYZ').to_quaternion()
                        bpy.context.view_layer.update()
                        g_i2 = b2g(arm.matrix_world @ pb_i2.head)
                        err = (g_i2 - target).length * 100.0
                        if err < best_err:
                            best_err = err
                            best_cfg = (
                                (-66.0, 41.8, round(34.2 + dua_z, 1)),
                                (0.0, round(-47.8 + dla_y, 1), round(4.2 + dla_z, 1)),
                                (round(13.5 + dh_x, 1), round(-25.0 + dh_y, 1), round(-7.2 + dh_z, 1)),
                                g_i2
                            )

print("BEST R RESULT:")
print("UA:", best_cfg[0])
print("LA:", best_cfg[1])
print("H: ", best_cfg[2])
s, c = torus(best_cfg[3])
print(f"Knuckle: {best_cfg[3]} | Err: {best_err:.2f} cm | Surf: {s:.2f} cm | Clock: {c:.1f}h")
