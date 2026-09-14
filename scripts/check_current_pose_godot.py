import bpy
import math
from mathutils import Vector, Euler, Quaternion

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

def blender_to_godot(v):
    return Vector((-0.36 - v.x, -0.33 + v.z, 0.13 + v.y))

wheel_center = Vector((-0.36, 0.79, -0.35))
tilt_rad = math.radians(-25.0)

def check_torus(p_godot):
    d = p_godot - wheel_center
    dy_untilted = d.y * math.cos(-tilt_rad) - d.z * math.sin(-tilt_rad)
    dz_untilted = d.y * math.sin(-tilt_rad) + d.z * math.cos(-tilt_rad)
    dx_untilted = d.x

    r_xy = math.sqrt(dx_untilted**2 + dy_untilted**2)
    dist_to_tube_centerline = math.sqrt((r_xy - 0.165)**2 + dz_untilted**2)
    dist_to_tube_surface = dist_to_tube_centerline - 0.015
    rim_angle_deg = math.degrees(math.atan2(dy_untilted, dx_untilted))
    if rim_angle_deg < 0:
        rim_angle_deg += 360.0

    return {
        "dist_surface_cm": dist_to_tube_surface * 100.0,
        "clock_pos": rim_angle_deg / 30.0,
        "dz_untilted_cm": dz_untilted * 100.0,
        "r_xy_cm": r_xy * 100.0
    }

BASE_POSTURE = {
    "Hips":       (-6.0, 0.0, 0.0),
    "Abdomen":    (-4.0, 0.0, 0.0),
    "Torso":      (-3.0, 0.0, 0.0),
    "Chest":      (-2.0, 0.0, 0.0),
    "Neck":       (0.0, 0.0, 0.0),
    "Head":       (15.0, 0.0, 0.0),
    "UpperArm.L": (-72.0, -25.2, -23.0),
    "LowerArm.L": (0.0, 27.9, -50.9),
    "Hand.L":     (-25.4, 47.0, 31.4),
    "UpperArm.R": (-72.0, 25.2, 23.0),
    "LowerArm.R": (0.0, -27.9, 50.9),
    "Hand.R":     (-25.4, -47.0, -31.4),
}

for bname, (rx, ry, rz) in BASE_POSTURE.items():
    pb = arm.pose.bones.get(bname)
    if pb:
        pb.rotation_quaternion = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), 'XYZ').to_quaternion()

bpy.context.view_layer.update()

for side in ["L", "R"]:
    is_left = (side == "L")
    target_godot = Vector((-0.5029, 0.8648, -0.3849)) if is_left else Vector((-0.2171, 0.8648, -0.3849))
    pb_ua = arm.pose.bones.get(f"UpperArm.{side}")
    pb_la = arm.pose.bones.get(f"LowerArm.{side}")
    pb_h  = arm.pose.bones.get(f"Hand.{side}")
    pb_i2 = arm.pose.bones.get(f"Index2.{side}")

    g_sh = blender_to_godot(arm.matrix_world @ pb_ua.head)
    g_el = blender_to_godot(arm.matrix_world @ pb_la.head)
    g_wr = blender_to_godot(arm.matrix_world @ pb_h.head)
    g_i2 = blender_to_godot(arm.matrix_world @ pb_i2.head)

    print(f"\n--- {side} SIDE CURRENT ---")
    print("Shoulder Godot:", g_sh)
    print("Elbow Godot:   ", g_el)
    print("Wrist Godot:   ", g_wr)
    print("Knuckle Godot: ", g_i2)
    print("Target Knuckle:", target_godot)
    print("Distance to Target:", (g_i2 - target_godot).length * 100.0, "cm")
    print("Distance Wrist to Target:", (g_wr - target_godot).length * 100.0, "cm")
    print("Knuckle Torus:", check_torus(g_i2))

