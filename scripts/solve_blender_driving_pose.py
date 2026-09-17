import bpy
import math
from mathutils import Vector, Euler, Quaternion

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

# Target Knuckle positions in Blender (where runner is at (-0.36, -0.33, 0.13) in Godot)
# Formula:
# X_godot = -0.36 - X_blender
# Y_godot = -0.33 + Z_blender
# Z_godot =  0.13 + Y_blender
def blender_to_godot(v):
    return Vector((-0.36 - v.x, -0.33 + v.z, 0.13 + v.y))

# Wheel geometry in Godot:
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
    "UpperLeg.L": (-18.0, 2.0, 25.0),
    "LowerLeg.L": (78.0, 0.0, -6.0),
    "Foot.L":     (-8.0, 0.0, 0.0),
    "UpperLeg.R": (-18.0, -2.0, -25.0),
    "LowerLeg.R": (78.0, 0.0, 6.0),
    "Foot.R":     (-8.0, 0.0, 0.0),
}

for bname, (rx, ry, rz) in BASE_POSTURE.items():
    pb = arm.pose.bones.get(bname)
    if pb:
        pb.rotation_quaternion = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), 'XYZ').to_quaternion()

bpy.context.view_layer.update()

# Target Godot Knuckle positions:
# 10 o'clock: (-0.5029, 0.8648, -0.3849) -> Blender (0.1429, -0.5149, 1.1948)
# 2 o'clock:  (-0.2171, 0.8648, -0.3849) -> Blender (-0.1429, -0.5149, 1.1948)

print("=== GRID SEARCHING EXACT BLENDER EULERS FOR LEFT & RIGHT ARMS ===")

# Solved container
results = {}

for side in ["L", "R"]:
    is_left = (side == "L")
    target_godot = Vector((-0.5029, 0.8648, -0.3849)) if is_left else Vector((-0.2171, 0.8648, -0.3849))
    
    pb_ua = arm.pose.bones.get(f"UpperArm.{side}")
    pb_la = arm.pose.bones.get(f"LowerArm.{side}")
    pb_h  = arm.pose.bones.get(f"Hand.{side}")
    pb_i2 = arm.pose.bones.get(f"Index2.{side}")
    pb_t2 = arm.pose.bones.get(f"Thumb2.{side}")
    pb_t3 = arm.pose.bones.get(f"Thumb3.{side}")

    best_score = 999999.0
    best_ua_euler = None
    best_la_euler = None
    best_h_euler = None
    best_info = {}

    # Initial search ranges around biomechanically sound automotive angles
    # For UpperArm:
    # X tilts arm up/down
    # Y twists arm
    # Z swings arm forward (-Z for L swings forward, +Z for R swings forward)
    ua_x_range = range(-85, -55, 3)
    ua_y_range = range(-35, 5, 5) if is_left else range(-5, 35, 5)
    ua_z_range = range(-75, -20, 5) if is_left else range(20, 75, 5)

    # Coarse pass
    for ua_x in ua_x_range:
        for ua_y in ua_y_range:
            for ua_z in ua_z_range:
                pb_ua.rotation_quaternion = Euler((math.radians(ua_x), math.radians(ua_y), math.radians(ua_z)), 'XYZ').to_quaternion()
                
                # LowerArm ranges (elbow flexion and forearm twist)
                la_y_range = range(10, 45, 6) if is_left else range(-45, -10, 6)
                la_z_range = range(-65, -25, 6) if is_left else range(25, 65, 6)
                for la_y in la_y_range:
                    for la_z in la_z_range:
                        pb_la.rotation_quaternion = Euler((0.0, math.radians(la_y), math.radians(la_z)), 'XYZ').to_quaternion()
                        
                        # Check wrist position
                        bpy.context.view_layer.update()
                        w_wrist = arm.matrix_world @ pb_h.head
                        g_wrist = blender_to_godot(w_wrist)

                        # Wrist height constraint: 0.83m to 0.89m (well below 0.94m rim apex)
                        if g_wrist.y > 0.90 or g_wrist.y < 0.81:
                            continue

                        # Wrist distance to knuckle target must be ~8-14cm
                        d_target = (g_wrist - target_godot).length
                        if d_target < 0.08 or d_target > 0.16:
                            continue

                        # Hand ranges
                        h_x_range = range(-45, 15, 8)
                        h_y_range = range(10, 55, 8) if is_left else range(-55, -10, 8)
                        h_z_range = range(10, 55, 8) if is_left else range(-55, -10, 8)
                        for h_x in h_x_range:
                            for h_y in h_y_range:
                                for h_z in h_z_range:
                                    pb_h.rotation_quaternion = Euler((math.radians(h_x), math.radians(h_y), math.radians(h_z)), 'XYZ').to_quaternion()
                                    bpy.context.view_layer.update()
                                    
                                    w_i2 = arm.matrix_world @ pb_i2.head
                                    g_i2 = blender_to_godot(w_i2)
                                    torus_info = check_torus(g_i2)
                                    
                                    err_target = (g_i2 - target_godot).length
                                    surf_err = abs(torus_info["dist_surface_cm"])
                                    
                                    # Clock check (10 o'clock = 5.0h in check_torus atan2, 2 o'clock = 1.0h)
                                    target_clock = 5.0 if is_left else 1.0
                                    clock_err = abs(torus_info["clock_pos"] - target_clock)

                                    score = err_target * 200.0 + surf_err * 2.0 + clock_err * 15.0 + abs(g_wrist.y - 0.85) * 50.0
                                    if score < best_score:
                                        best_score = score
                                        best_ua_euler = (ua_x, ua_y, ua_z)
                                        best_la_euler = (0.0, la_y, la_z)
                                        best_h_euler  = (h_x, h_y, h_z)
                                        best_info = {
                                            "err_target_cm": err_target * 100.0,
                                            "surf_cm": torus_info["dist_surface_cm"],
                                            "clock": torus_info["clock_pos"],
                                            "g_wrist": g_wrist,
                                            "g_i2": g_i2
                                        }

    print(f"\n--- BEST COARSE FOR {side} (Score {best_score:.2f}) ---")
    print("UpperArm:", best_ua_euler)
    print("LowerArm:", best_la_euler)
    print("Hand:    ", best_h_euler)
    print("Info:    ", best_info)

    # Fine pass around best
    fine_score = best_score
    b_uax, b_uay, b_uaz = best_ua_euler
    _, b_lay, b_laz = best_la_euler
    b_hx, b_hy, b_hz = best_h_euler

    for duax in [-3, -2, -1, 0, 1, 2, 3]:
        for duaz in [-3, -2, -1, 0, 1, 2, 3]:
            ua_e = (b_uax + duax, b_uay, b_uaz + duaz)
            pb_ua.rotation_quaternion = Euler((math.radians(ua_e[0]), math.radians(ua_e[1]), math.radians(ua_e[2])), 'XYZ').to_quaternion()
            for dlay in [-3, -2, -1, 0, 1, 2, 3]:
                for dlaz in [-3, -2, -1, 0, 1, 2, 3]:
                    la_e = (0.0, b_lay + dlay, b_laz + dlaz)
                    pb_la.rotation_quaternion = Euler((0.0, math.radians(la_e[1]), math.radians(la_e[2])), 'XYZ').to_quaternion()
                    for dhx in [-4, -2, 0, 2, 4]:
                        for dhy in [-4, -2, 0, 2, 4]:
                            for dhz in [-4, -2, 0, 2, 4]:
                                h_e = (b_hx + dhx, b_hy + dhy, b_hz + dhz)
                                pb_h.rotation_quaternion = Euler((math.radians(h_e[0]), math.radians(h_e[1]), math.radians(h_e[2])), 'XYZ').to_quaternion()
                                bpy.context.view_layer.update()

                                w_i2 = arm.matrix_world @ pb_i2.head
                                g_i2 = blender_to_godot(w_i2)
                                w_wrist = arm.matrix_world @ pb_h.head
                                g_wrist = blender_to_godot(w_wrist)

                                torus_info = check_torus(g_i2)
                                err_target = (g_i2 - target_godot).length
                                surf_err = abs(torus_info["dist_surface_cm"])
                                target_clock = 5.0 if is_left else 1.0
                                clock_err = abs(torus_info["clock_pos"] - target_clock)

                                score = err_target * 300.0 + surf_err * 3.0 + clock_err * 20.0 + abs(g_wrist.y - 0.85) * 50.0
                                if score < fine_score:
                                    fine_score = score
                                    best_ua_euler = ua_e
                                    best_la_euler = la_e
                                    best_h_euler  = h_e
                                    best_info = {
                                        "err_target_cm": err_target * 100.0,
                                        "surf_cm": torus_info["dist_surface_cm"],
                                        "clock": torus_info["clock_pos"],
                                        "g_wrist": g_wrist,
                                        "g_i2": g_i2
                                    }

    print(f"\n--- FINE SOLVED FOR {side} (Score {fine_score:.2f}) ---")
    print(f'"UpperArm.{side}": {best_ua_euler},')
    print(f'"LowerArm.{side}": {best_la_euler},')
    print(f'"Hand.{side}":     {best_h_euler},')
    print("Final Knuckle Godot Pos:", best_info["g_i2"])
    print("Final Wrist Godot Pos:  ", best_info["g_wrist"])
    print(f"Target Err: {best_info['err_target_cm']:.2f} cm | Surf Dist: {best_info['surf_cm']:.2f} cm | Clock: {best_info['clock']:.1f}h")

    # Now solve Thumb so Thumb3 hooks inner rim
    pb_ua.rotation_quaternion = Euler((math.radians(best_ua_euler[0]), math.radians(best_ua_euler[1]), math.radians(best_ua_euler[2])), 'XYZ').to_quaternion()
    pb_la.rotation_quaternion = Euler((math.radians(best_la_euler[0]), math.radians(best_la_euler[1]), math.radians(best_la_euler[2])), 'XYZ').to_quaternion()
    pb_h.rotation_quaternion  = Euler((math.radians(best_h_euler[0]), math.radians(best_h_euler[1]), math.radians(best_h_euler[2])), 'XYZ').to_quaternion()

    best_thumb_score = 99999.0
    best_t2_euler = (0,0,0)
    best_t3_euler = (0,0,0)
    best_t_info = {}

    for t2_x in range(-60, 20, 10):
        for t2_y in range(-40, 40, 10):
            for t2_z in range(-40, 40, 10):
                pb_t2.rotation_quaternion = Euler((math.radians(t2_x), math.radians(t2_y), math.radians(t2_z)), 'XYZ').to_quaternion()
                for t3_x in range(-60, 20, 10):
                    pb_t3.rotation_quaternion = Euler((math.radians(t3_x), 0.0, 0.0), 'XYZ').to_quaternion()
                    bpy.context.view_layer.update()

                    w_t3 = arm.matrix_world @ pb_t3.head
                    g_t3 = blender_to_godot(w_t3)
                    t_info = check_torus(g_t3)

                    # Thumb should be inside rim (r_xy < 17.5cm) and near surface
                    surf_dist = abs(t_info["dist_surface_cm"])
                    if t_info["r_xy_cm"] < 17.0 and surf_dist < best_thumb_score:
                        best_thumb_score = surf_dist
                        best_t2_euler = (t2_x, t2_y, t2_z)
                        best_t3_euler = (t3_x, 0.0, 0.0)
                        best_t_info = t_info

    print(f'"Thumb2.{side}":   {best_t2_euler},')
    print(f'"Thumb3.{side}":   {best_t3_euler},')
    print("Thumb3 Surf Dist:", best_t_info.get("dist_surface_cm", 999), "cm")

