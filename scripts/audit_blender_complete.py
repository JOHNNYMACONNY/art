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
    return {
        "surf_cm": s * 100.0,
        "clock": a / 30.0,
        "r_cm": r * 100.0,
        "dz_cm": dz * 100.0
    }

POSTURE = {
    "Hips":       (-6.0, 0.0, 0.0),
    "Abdomen":    (-4.0, 0.0, 0.0),
    "Torso":      (-3.0, 0.0, 0.0),
    "Chest":      (-2.0, 0.0, 0.0),
    "Neck":       (0.0, 0.0, 0.0),
    "Head":       (15.0, 0.0, 0.0),

    # Solved Left Arm
    "UpperArm.L": (-70.5, -25.4, -24.1),
    "LowerArm.L": (0.0, 58.2, -27.2),
    "Hand.L":     (16.1, 20.4, 12.4),
    "Thumb2.L":   (-25.0, 51.5, 40.0),
    "Thumb3.L":   (-35.0, 0.0, 0.0),

    # Solved Right Arm
    "UpperArm.R": (-66.0, 41.8, 34.2),
    "LowerArm.R": (0.0, -47.8, 6.2),
    "Hand.R":     (7.5, -19.0, -7.2),
    "Thumb2.R":   (-12.0, -96.5, -46.0),
    "Thumb3.R":   (-35.0, 0.0, 0.0),

    # Legs
    "UpperLeg.L": (-18.0, 2.0, 25.0),
    "LowerLeg.L": (78.0, 0.0, -6.0),
    "Foot.L":     (-8.0, 0.0, 0.0),
    "UpperLeg.R": (-18.0, -2.0, -25.0),
    "LowerLeg.R": (78.0, 0.0, 6.0),
    "Foot.R":     (-8.0, 0.0, 0.0),
}

# Finger curl around 3cm cylindrical rim
FINGERS = {
    "Index2":  (-60.0, 0.0, 0.0), "Index3":  (-75.0, 0.0, 0.0), "Index4":  (-55.0, 0.0, 0.0),
    "Middle2": (-62.0, 0.0, 0.0), "Middle3": (-78.0, 0.0, 0.0), "Middle4": (-55.0, 0.0, 0.0),
    "Ring2":   (-60.0, 0.0, 0.0), "Ring3":   (-75.0, 0.0, 0.0), "Ring4":   (-52.0, 0.0, 0.0),
    "Pinky2":  (-58.0, 0.0, 0.0), "Pinky3":  (-72.0, 0.0, 0.0), "Pinky4":  (-48.0, 0.0, 0.0),
}

for b, r in POSTURE.items():
    arm.pose.bones[b].rotation_quaternion = Euler(tuple(map(math.radians, r)), 'XYZ').to_quaternion()

for side in ["L", "R"]:
    for f, r in FINGERS.items():
        arm.pose.bones[f"{f}.{side}"].rotation_quaternion = Euler(tuple(map(math.radians, r)), 'XYZ').to_quaternion()

bpy.context.view_layer.update()

print("\n================ COMPREHENSIVE BIOMECHANICS AUDIT ================")
for side in ["L", "R"]:
    print(f"\n[{side} SIDE AUDIT]")
    pb_ua = arm.pose.bones[f"UpperArm.{side}"]
    pb_la = arm.pose.bones[f"LowerArm.{side}"]
    pb_h  = arm.pose.bones[f"Hand.{side}"]

    g_sh = b2g(arm.matrix_world @ pb_ua.head)
    g_el = b2g(arm.matrix_world @ pb_la.head)
    g_wr = b2g(arm.matrix_world @ pb_h.head)

    print(f"Shoulder pos: ({g_sh.x:+.3f}, {g_sh.y:+.3f}, {g_sh.z:+.3f})")
    print(f"Elbow pos:    ({g_el.x:+.3f}, {g_el.y:+.3f}, {g_el.z:+.3f}) | Height vs center: {(g_el.y - wc.y)*100:+.1f}cm")
    print(f"Wrist pos:    ({g_wr.x:+.3f}, {g_wr.y:+.3f}, {g_wr.z:+.3f}) | Height vs center: {(g_wr.y - wc.y)*100:+.1f}cm")

    bones_to_eval = [
        "Index2", "Index3", "Index4",
        "Middle2", "Middle3", "Middle4",
        "Thumb2", "Thumb3"
    ]
    for b in bones_to_eval:
        pb = arm.pose.bones[f"{b}.{side}"]
        pos = b2g(arm.matrix_world @ pb.head)
        t = torus(pos)
        state = "SURFACE CONTACT" if abs(t['surf_cm']) < 2.0 else ("PENETRATING MESH" if t['surf_cm'] < -2.0 else "AIR GAP")
        print(f"  {b:8s}.{side}: Pos=({pos.x:+.3f}, {pos.y:+.3f}, {pos.z:+.3f}) | SurfDist={t['surf_cm']:+5.2f}cm | Clock={t['clock']:4.1f}h | {state}")

