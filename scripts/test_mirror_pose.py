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
    "UpperArm.L": (-71.0, -25.2, -23.6),
    "LowerArm.L": (0.0, 64.0, -30.5),
    "Hand.L":     (10.6, 23.2, 14.2),
    "UpperArm.R": (-71.0, 25.2, 23.6),
    "LowerArm.R": (0.0, -64.0, 30.5),
    "Hand.R":     (10.6, -23.2, -14.2),
}

for bname, (rx, ry, rz) in BASE_POSTURE.items():
    pb = arm.pose.bones.get(bname)
    if pb:
        pb.rotation_quaternion = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), 'XYZ').to_quaternion()

bpy.context.view_layer.update()

for side in ["L", "R"]:
    is_left = (side == "L")
    target = Vector((-0.5029, 0.8648, -0.3849)) if is_left else Vector((-0.2171, 0.8648, -0.3849))
    pb_i2 = arm.pose.bones.get(f"Index2.{side}")
    pb_h  = arm.pose.bones.get(f"Hand.{side}")
    pb_la = arm.pose.bones.get(f"LowerArm.{side}")

    g_wr = blender_to_godot(arm.matrix_world @ pb_h.head)
    g_i2 = blender_to_godot(arm.matrix_world @ pb_i2.head)
    g_el = blender_to_godot(arm.matrix_world @ pb_la.head)
    t = check_torus(g_i2)
    err = (g_i2 - target).length * 100.0

    print(f"\n--- {side} SIDE MIRROR TEST ---")
    print("Knuckle target: ", target)
    print("Knuckle pos:    ", g_i2)
    print(f"Knuckle Error:  {err:.2f} cm")
    print(f"Surface Dist:   {t['dist_surface_cm']:.2f} cm (Clock {t['clock_pos']:.1f}h)")
    print("Wrist pos:      ", g_wr, f" (Height: {g_wr.y:.3f}m)")
    print("Elbow pos:      ", g_el, f" (Height: {g_el.y:.3f}m)")

