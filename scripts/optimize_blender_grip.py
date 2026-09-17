import bpy
import math
import random
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

# We optimize L and R
target_L = Vector((-0.5029, 0.8648, -0.3849))
target_R = Vector((-0.2171, 0.8648, -0.3849))

solved_rotations = {}

for side in ["L", "R"]:
    is_left = (side == "L")
    target = target_L if is_left else target_R
    target_clock = 5.0 if is_left else 1.0

    pb_ua = arm.pose.bones.get(f"UpperArm.{side}")
    pb_la = arm.pose.bones.get(f"LowerArm.{side}")
    pb_h  = arm.pose.bones.get(f"Hand.{side}")
    pb_i2 = arm.pose.bones.get(f"Index2.{side}")

    # Starting angles from existing pose
    if is_left:
        cur_angles = [-72.0, -25.2, -23.0, 27.9, -50.9, -25.4, 47.0, 31.4]
    else:
        cur_angles = [-72.0, 25.2, 23.0, -27.9, 50.9, -25.4, -47.0, -31.4]

    def eval_angles(angles):
        ua_x, ua_y, ua_z, la_y, la_z, h_x, h_y, h_z = angles
        pb_ua.rotation_quaternion = Euler((math.radians(ua_x), math.radians(ua_y), math.radians(ua_z)), 'XYZ').to_quaternion()
        pb_la.rotation_quaternion = Euler((0.0, math.radians(la_y), math.radians(la_z)), 'XYZ').to_quaternion()
        pb_h.rotation_quaternion  = Euler((math.radians(h_x), math.radians(h_y), math.radians(h_z)), 'XYZ').to_quaternion()
        bpy.context.view_layer.update()

        g_el = blender_to_godot(arm.matrix_world @ pb_la.head)
        g_wr = blender_to_godot(arm.matrix_world @ pb_h.head)
        g_i2 = blender_to_godot(arm.matrix_world @ pb_i2.head)

        torus = check_torus(g_i2)
        err_knuckle_cm = (g_i2 - target).length * 100.0
        surf_dist_cm = abs(torus["dist_surface_cm"])
        clock_diff = abs(torus["clock_pos"] - target_clock)

        # Biomechanical posture penalties:
        # Ideal wrist height: 0.86 - 0.89m
        wrist_pen = 0.0
        if g_wr.y > 0.90:
            wrist_pen += (g_wr.y - 0.90) * 800.0
        elif g_wr.y < 0.82:
            wrist_pen += (0.82 - g_wr.y) * 400.0

        # Ideal elbow height: 0.76 - 0.84m
        elbow_pen = 0.0
        if g_el.y > 0.86:
            elbow_pen += (g_el.y - 0.86) * 400.0

        # Forearm direction: wrist should be behind knuckle (g_wr.z > g_i2.z in Godot)
        direction_pen = 0.0
        if g_wr.z < g_i2.z + 0.04:
            direction_pen += ((g_i2.z + 0.04) - g_wr.z) * 500.0

        total_cost = (
            err_knuckle_cm * 10.0 +
            surf_dist_cm * 5.0 +
            clock_diff * 15.0 +
            wrist_pen +
            elbow_pen +
            direction_pen
        )
        return total_cost, {
            "err_knuckle_cm": err_knuckle_cm,
            "surf_dist_cm": torus["dist_surface_cm"],
            "clock_pos": torus["clock_pos"],
            "wrist_pos": g_wr,
            "elbow_pos": g_el,
            "knuckle_pos": g_i2,
        }

    best_cost, best_info = eval_angles(cur_angles)
    best_angles = list(cur_angles)
    print(f"Starting cost for {side}: {best_cost:.2f}")

    # Coordinate descent with adaptive step sizes
    steps = [8.0, 4.0, 2.0, 1.0, 0.5, 0.2]
    for step in steps:
        for iteration in range(15):
            improved = False
            for i in range(len(best_angles)):
                for delta in [-step, step]:
                    cand = list(best_angles)
                    cand[i] += delta
                    cost, info = eval_angles(cand)
                    if cost < best_cost:
                        best_cost = cost
                        best_angles = cand
                        best_info = info
                        improved = True
            if not improved:
                break

    print(f"\n--- OPTIMIZATION RESULT FOR {side} (Final Cost: {best_cost:.2f}) ---")
    ua_x, ua_y, ua_z, la_y, la_z, h_x, h_y, h_z = best_angles
    print(f'"UpperArm.{side}": ({ua_x:.1f}, {ua_y:.1f}, {ua_z:.1f}),')
    print(f'"LowerArm.{side}": (0.0, {la_y:.1f}, {la_z:.1f}),')
    print(f'"Hand.{side}":     ({h_x:.1f}, {h_y:.1f}, {h_z:.1f}),')
    print("Knuckle target: ", target)
    print("Knuckle pos:    ", best_info["knuckle_pos"])
    print(f"Knuckle Error:  {best_info['err_knuckle_cm']:.2f} cm")
    print(f"Surface Dist:   {best_info['surf_dist_cm']:.2f} cm (Clock {best_info['clock_pos']:.1f}h)")
    print("Wrist pos:      ", best_info["wrist_pos"], f" (Height: {best_info['wrist_pos'].y:.3f}m)")
    print("Elbow pos:      ", best_info["elbow_pos"], f" (Height: {best_info['elbow_pos'].y:.3f}m)")

    solved_rotations[f"UpperArm.{side}"] = (round(ua_x, 1), round(ua_y, 1), round(ua_z, 1))
    solved_rotations[f"LowerArm.{side}"] = (0.0, round(la_y, 1), round(la_z, 1))
    solved_rotations[f"Hand.{side}"]     = (round(h_x, 1), round(h_y, 1), round(h_z, 1))

    # Now solve Thumb so Thumb3 hooks inner rim
    pb_t2 = arm.pose.bones.get(f"Thumb2.{side}")
    pb_t3 = arm.pose.bones.get(f"Thumb3.{side}")
    cur_t_angles = [-30.0, 10.0, 15.0, -40.0] if is_left else [-25.0, -10.0, -15.0, -35.0]

    def eval_thumb(t_angles):
        t2_x, t2_y, t2_z, t3_x = t_angles
        pb_t2.rotation_quaternion = Euler((math.radians(t2_x), math.radians(t2_y), math.radians(t2_z)), 'XYZ').to_quaternion()
        pb_t3.rotation_quaternion = Euler((math.radians(t3_x), 0.0, 0.0), 'XYZ').to_quaternion()
        bpy.context.view_layer.update()

        g_t3 = blender_to_godot(arm.matrix_world @ pb_t3.head)
        torus = check_torus(g_t3)
        surf_cm = abs(torus["dist_surface_cm"])
        
        # Inner rim check: radius r_xy should be <= 16.5cm (inside the outer rim)
        radius_pen = 0.0
        if torus["r_xy_cm"] > 16.5:
            radius_pen = (torus["r_xy_cm"] - 16.5) * 50.0

        cost = surf_cm * 10.0 + radius_pen
        return cost, torus, g_t3

    best_t_cost, best_t_info, best_t_pos = eval_thumb(cur_t_angles)
    best_t_angles = list(cur_t_angles)
    for step in [8.0, 4.0, 2.0, 1.0, 0.5]:
        for iteration in range(10):
            improved = False
            for i in range(len(best_t_angles)):
                for delta in [-step, step]:
                    cand = list(best_t_angles)
                    cand[i] += delta
                    cost, info, pos = eval_thumb(cand)
                    if cost < best_t_cost:
                        best_t_cost = cost
                        best_t_angles = cand
                        best_t_info = info
                        best_t_pos = pos
                        improved = True
            if not improved:
                break

    t2_x, t2_y, t2_z, t3_x = best_t_angles
    print(f'"Thumb2.{side}":   ({t2_x:.1f}, {t2_y:.1f}, {t2_z:.1f}),')
    print(f'"Thumb3.{side}":   ({t3_x:.1f}, 0.0, 0.0),')
    print(f"Thumb3 Surf Dist: {best_t_info['dist_surface_cm']:.2f} cm (Radius: {best_t_info['r_xy_cm']:.2f} cm)")
    solved_rotations[f"Thumb2.{side}"] = (round(t2_x, 1), round(t2_y, 1), round(t2_z, 1))
    solved_rotations[f"Thumb3.{side}"] = (round(t3_x, 1), 0.0, 0.0)

print("\n\n=== COMPLETE SOLVED ROTATION DICT ===")
print(solved_rotations)

