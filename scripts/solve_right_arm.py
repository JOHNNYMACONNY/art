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
    "UpperLeg.R": (-18.0, -2.0, -25.0),
    "LowerLeg.R": (78.0, 0.0, 6.0),
    "Foot.R":     (-8.0, 0.0, 0.0),
}

for bname, (rx, ry, rz) in BASE_POSTURE.items():
    pb = arm.pose.bones.get(bname)
    if pb:
        pb.rotation_quaternion = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), 'XYZ').to_quaternion()

bpy.context.view_layer.update()

target = Vector((-0.2171, 0.8648, -0.3849))
target_clock = 1.0

pb_ua = arm.pose.bones.get("UpperArm.R")
pb_la = arm.pose.bones.get("LowerArm.R")
pb_h  = arm.pose.bones.get("Hand.R")
pb_i2 = arm.pose.bones.get("Index2.R")

best_score = 99999.0
best_sol = None
best_info = None

# Broad grid search on R arm angles
for ua_x in range(-78, -64, 2):
    for ua_y in range(15, 35, 3):
        for ua_z in range(25, 55, 3):
            pb_ua.rotation_quaternion = Euler((math.radians(ua_x), math.radians(ua_y), math.radians(ua_z)), 'XYZ').to_quaternion()
            for la_y in range(-55, -25, 4):
                for la_z in range(15, 45, 4):
                    pb_la.rotation_quaternion = Euler((0.0, math.radians(la_y), math.radians(la_z)), 'XYZ').to_quaternion()
                    bpy.context.view_layer.update()
                    
                    g_wr = blender_to_godot(arm.matrix_world @ pb_h.head)
                    if g_wr.y > 0.92 or g_wr.y < 0.82:
                        continue
                    
                    for h_x in range(0, 35, 5):
                        for h_y in range(-35, -5, 5):
                            for h_z in range(-25, 5, 5):
                                pb_h.rotation_quaternion = Euler((math.radians(h_x), math.radians(h_y), math.radians(h_z)), 'XYZ').to_quaternion()
                                bpy.context.view_layer.update()

                                g_i2 = blender_to_godot(arm.matrix_world @ pb_i2.head)
                                torus = check_torus(g_i2)
                                err_knuckle_cm = (g_i2 - target).length * 100.0
                                surf_cm = abs(torus["dist_surface_cm"])
                                clock_diff = abs(torus["clock_pos"] - target_clock)

                                score = err_knuckle_cm * 50.0 + surf_cm * 20.0 + clock_diff * 30.0 + abs(g_wr.y - 0.86) * 100.0
                                if score < best_score:
                                    best_score = score
                                    best_sol = (ua_x, ua_y, ua_z, la_y, la_z, h_x, h_y, h_z)
                                    best_info = {
                                        "err_knuckle_cm": err_knuckle_cm,
                                        "surf_dist_cm": torus["dist_surface_cm"],
                                        "clock_pos": torus["clock_pos"],
                                        "wrist_pos": g_wr,
                                        "knuckle_pos": g_i2,
                                    }

print("=== BEST GRID SEARCH FOR R ARM ===")
print("Best Sol:", best_sol)
print("Best Info:", best_info)

