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

pb_ua = arm.pose.bones.get("UpperArm.R")
pb_la = arm.pose.bones.get("LowerArm.R")
pb_h  = arm.pose.bones.get("Hand.R")
pb_i2 = arm.pose.bones.get("Index2.R")

target = Vector((-0.2171, 0.8648, -0.3849))

print("--- SWEEPING UPPERARM.R Z ROTATION ---")
for ua_z in [20, 35, 50, 65, 75]:
    for ua_x in [-75, -65, -55, -45]:
        pb_ua.rotation_quaternion = Euler((math.radians(ua_x), math.radians(20), math.radians(ua_z)), 'XYZ').to_quaternion()
        pb_la.rotation_quaternion = Euler((0.0, math.radians(-25), math.radians(45)), 'XYZ').to_quaternion()
        pb_h.rotation_quaternion  = Euler((math.radians(-10), math.radians(-20), math.radians(-20)), 'XYZ').to_quaternion()
        bpy.context.view_layer.update()

        g_el = blender_to_godot(arm.matrix_world @ pb_la.head)
        g_wr = blender_to_godot(arm.matrix_world @ pb_h.head)
        g_i2 = blender_to_godot(arm.matrix_world @ pb_i2.head)
        t = check_torus(g_i2)
        dist = (g_i2 - target).length * 100.0
        print(f"ua_x={ua_x:+3d} ua_z={ua_z:+3d} -> i2=({g_i2.x:+.3f},{g_i2.y:+.3f},{g_i2.z:+.3f}) dist={dist:4.1f}cm surf={t['dist_surface_cm']:+4.1f}cm wrist_y={g_wr.y:.3f} el_y={g_el.y:.3f}")

