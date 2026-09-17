import bpy
import math
from mathutils import Matrix, Vector, Euler, Quaternion

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

# Spine posture
SPINE_ROTS = {
    "Hips":       (-6.0, 0.0, 0.0),
    "Abdomen":    (-4.0, 0.0, 0.0),
    "Torso":      (-3.0, 0.0, 0.0),
    "Chest":      (-2.0, 0.0, 0.0),
    "Head":       (15.0, 0.0, 0.0),
}

for bname, (rx, ry, rz) in SPINE_ROTS.items():
    pb = arm.pose.bones.get(bname)
    if pb:
        pb.rotation_quaternion = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), 'XYZ').to_quaternion()

# Targets in Blender:
# Left Knuckle:  (+0.1429, -0.5149, 1.1948)
# Right Knuckle: (-0.1429, -0.5149, 1.1948)
target_L = Vector((0.1429, -0.5149, 1.1948))
target_R = Vector((-0.1429, -0.5149, 1.1948))

print("Target Left: ", target_L)
print("Target Right:", target_R)

# Solve for each side
for side, target in [("L", target_L), ("R", target_R)]:
    is_left = (side == "L")
    b_ua = arm.pose.bones[f"UpperArm.{side}"]
    b_la = arm.pose.bones[f"LowerArm.{side}"]
    b_h  = arm.pose.bones[f"Hand.{side}"]
    b_i2 = arm.pose.bones[f"Index2.{side}"]
    
    # We search over Euler rotations (rx, ry, rz)
    best_err = 999.0
    best_rots = None
    best_wrist = Vector((0, 0, 0))
    best_k = Vector((0, 0, 0))
    
    # Range of shoulder angles
    ua_x_range = range(-80, -50, 4)
    ua_y_range = range(-35, 36, 6)
    ua_z_range = range(-35, 36, 6)
    
    # Range of elbow angles (LowerArm)
    la_z_range = range(-70, -30, 4) if is_left else range(30, 71, 4)
    la_y_range = range(10, 45, 6) if is_left else range(-45, -9, 6)
    
    for ua_x in ua_x_range:
        for ua_y in ua_y_range:
            for ua_z in ua_z_range:
                b_ua.rotation_quaternion = Euler((math.radians(ua_x), math.radians(ua_y), math.radians(ua_z)), 'XYZ').to_quaternion()
                for la_z in la_z_range:
                    for la_y in la_y_range:
                        b_la.rotation_quaternion = Euler((0.0, math.radians(la_y), math.radians(la_z)), 'XYZ').to_quaternion()
                        bpy.context.view_layer.update()
                        
                        # Wrist position check
                        p_w = b_h.head
                        d_w = (p_w - target).length
                        # Wrist should be 8-15cm away from knuckle target
                        if d_w < 0.08 or d_w > 0.15:
                            continue
                            
                        # Now search Hand orientation
                        for h_x in range(-50, 51, 15):
                            for h_y in range(-50, 51, 15):
                                for h_z in range(-50, 51, 15):
                                    b_h.rotation_quaternion = Euler((math.radians(h_x), math.radians(h_y), math.radians(h_z)), 'XYZ').to_quaternion()
                                    bpy.context.view_layer.update()
                                    
                                    p_k = b_i2.head
                                    err = (p_k - target).length
                                    if err < best_err:
                                        best_err = err
                                        best_rots = {
                                            "UpperArm": (ua_x, ua_y, ua_z),
                                            "LowerArm": (0.0, la_y, la_z),
                                            "Hand":     (h_x, h_y, h_z)
                                        }
                                        best_wrist = p_w.copy()
                                        best_k = p_k.copy()

    print(f"\n--- SIDE {side} SOLVER RESULTS ---")
    print(f"Knuckle Error: {best_err * 100.0:.2f} cm")
    print("UpperArm: ", best_rots["UpperArm"])
    print("LowerArm: ", best_rots["LowerArm"])
    print("Hand:     ", best_rots["Hand"])
    print(f"Wrist pos:   ({best_wrist.x:.3f}, {best_wrist.y:.3f}, {best_wrist.z:.3f})")
    print(f"Knuckle pos: ({best_k.x:.3f}, {best_k.y:.3f}, {best_k.z:.3f}) vs Target: ({target.x:.3f}, {target.y:.3f}, {target.z:.3f})")
