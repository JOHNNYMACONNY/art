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

target_L = Vector((-0.5029, 0.8648, -0.3849))
target_R = Vector((-0.2171, 0.8648, -0.3849))

solved_arms = {}

# Solve Left then Right
configs = [
    ("L", target_L, 5.0, [-71.0, -25.2, -23.6, 64.0, -30.5, 10.6, 23.2, 14.2]),
    ("R", target_R, 1.0, [-71.0,  25.2,  23.6, -64.0, 30.5, 10.6, -23.2, -14.2]),
]

for side, target, target_clock, init_angles in configs:
    pb_ua = arm.pose.bones.get(f"UpperArm.{side}")
    pb_la = arm.pose.bones.get(f"LowerArm.{side}")
    pb_h  = arm.pose.bones.get(f"Hand.{side}")
    pb_i2 = arm.pose.bones.get(f"Index2.{side}")

    def evaluate(angles):
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
        surf_cm = abs(torus["dist_surface_cm"])
        clock_err = abs(torus["clock_pos"] - target_clock)

        # Penalties:
        # Knuckle position accuracy
        cost = err_knuckle_cm * 20.0 + surf_cm * 10.0 + clock_err * 25.0

        # Wrist height penalty: relaxed posture (0.83m to 0.88m)
        if g_wr.y > 0.89:
            cost += (g_wr.y - 0.89) * 1500.0
        elif g_wr.y < 0.82:
            cost += (0.82 - g_wr.y) * 600.0

        # Elbow height penalty: relaxed posture (0.75m to 0.84m)
        if g_el.y > 0.85:
            cost += (g_el.y - 0.85) * 800.0

        # Forearm direction penalty (wrist should be behind knuckle in Godot: g_wr.z > g_i2.z)
        if g_wr.z < g_i2.z + 0.05:
            cost += ((g_i2.z + 0.05) - g_wr.z) * 1000.0

        return cost, {
            "err_knuckle_cm": err_knuckle_cm,
            "surf_dist_cm": torus["dist_surface_cm"],
            "clock_pos": torus["clock_pos"],
            "wrist_pos": g_wr,
            "elbow_pos": g_el,
            "knuckle_pos": g_i2,
        }

    # Step descent with random restarts and wide bounds
    best_cost, best_info = evaluate(init_angles)
    best_angles = list(init_angles)

    print(f"\nStarting optimization for {side} (Initial Cost: {best_cost:.2f})")

    # Coarse search to lower elbow if possible
    # We test different UpperArm Z angles (forward swing) and LowerArm flexion
    for pass_num in range(3):
        for step in [12.0, 6.0, 3.0, 1.5, 0.75, 0.25]:
            for iteration in range(20):
                improved = False
                for i in range(len(best_angles)):
                    for delta in [-step, step]:
                        cand = list(best_angles)
                        cand[i] += delta
                        cost, info = evaluate(cand)
                        if cost < best_cost:
                            best_cost = cost
                            best_angles = cand
                            best_info = info
                            improved = True
                if not improved:
                    break

    print(f"\n--- OPTIMIZATION RESULT FOR {side} (Cost: {best_cost:.2f}) ---")
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

    solved_arms[f"UpperArm.{side}"] = (round(ua_x, 1), round(ua_y, 1), round(ua_z, 1))
    solved_arms[f"LowerArm.{side}"] = (0.0, round(la_y, 1), round(la_z, 1))
    solved_arms[f"Hand.{side}"]     = (round(h_x, 1), round(h_y, 1), round(h_z, 1))

    # Now solve Thumbs for this side
    pb_t2 = arm.pose.bones.get(f"Thumb2.{side}")
    pb_t3 = arm.pose.bones.get(f"Thumb3.{side}")
    t_init = [-20.0, 20.0, 20.0, -35.0] if side == "L" else [-20.0, -20.0, -20.0, -35.0]

    def eval_thumb(t_angles):
        t2_x, t2_y, t2_z, t3_x = t_angles
        pb_t2.rotation_quaternion = Euler((math.radians(t2_x), math.radians(t2_y), math.radians(t2_z)), 'XYZ').to_quaternion()
        pb_t3.rotation_quaternion = Euler((math.radians(t3_x), 0.0, 0.0), 'XYZ').to_quaternion()
        bpy.context.view_layer.update()

        g_t3 = blender_to_godot(arm.matrix_world @ pb_t3.head)
        torus = check_torus(g_t3)
        surf_cm = abs(torus["dist_surface_cm"])
        
        # Inner rim check: radius r_xy <= 16.5cm
        radius_pen = 0.0
        if torus["r_xy_cm"] > 16.5:
            radius_pen = (torus["r_xy_cm"] - 16.5) * 80.0
        # Thumb shouldn't penetrate deeply (< 0.5cm penetration)
        pen_pen = 0.0
        if torus["dist_surface_cm"] < -0.5:
            pen_pen = abs(torus["dist_surface_cm"] + 0.5) * 50.0

        cost = surf_cm * 10.0 + radius_pen + pen_pen
        return cost, torus, g_t3

    best_t_cost, best_t_info, _ = eval_thumb(t_init)
    best_t_angles = list(t_init)
    for step in [10.0, 5.0, 2.0, 1.0, 0.5]:
        for iteration in range(15):
            improved = False
            for i in range(len(best_t_angles)):
                for delta in [-step, step]:
                    cand = list(best_t_angles)
                    cand[i] += delta
                    cost, info, _ = eval_thumb(cand)
                    if cost < best_t_cost:
                        best_t_cost = cost
                        best_t_angles = cand
                        best_t_info = info
                        improved = True
            if not improved:
                break

    t2_x, t2_y, t2_z, t3_x = best_t_angles
    print(f'"Thumb2.{side}":   ({t2_x:.1f}, {t2_y:.1f}, {t2_z:.1f}),')
    print(f'"Thumb3.{side}":   ({t3_x:.1f}, 0.0, 0.0),')
    print(f"Thumb3 Surf Dist: {best_t_info['dist_surface_cm']:.2f} cm (Radius: {best_t_info['r_xy_cm']:.2f} cm)")
    solved_arms[f"Thumb2.{side}"] = (round(t2_x, 1), round(t2_y, 1), round(t2_z, 1))
    solved_arms[f"Thumb3.{side}"] = (round(t3_x, 1), 0.0, 0.0)

print("\n\n================ FINAL SOLVED ROTATIONS ================")
for k, v in solved_arms.items():
    print(f'    "{k}": {v},')

