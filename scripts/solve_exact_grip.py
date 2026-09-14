import bpy
import math
from mathutils import Euler, Vector, Matrix

# Script to optimize arm and hand angles to place:
# 1. Knuckle (Index2.L) within 1cm of 10 o'clock rim top: Godot (-0.50, 0.875, -0.380)
# 2. Knuckle (Index2.R) within 1cm of 2 o'clock rim top:  Godot (-0.22, 0.875, -0.380)
# 3. Palm resting against rim face
# 4. Fingers wrapped tightly around 3cm tube

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

# Target in Godot coordinates (unrotated coupe):
# Runner root in Godot is at (-0.36, -0.33, 0.13)
# So bone position in Godot:
# P_godot = P_runner_root + (Blender_X, Blender_Z, -Blender_Y)
# => Blender_X = P_godot.x - (-0.36) = P_godot.x + 0.36
# => Blender_Z = P_godot.y - (-0.33) = P_godot.y + 0.33
# => Blender_Y = -(P_godot.z - 0.13) = -P_godot.z + 0.13

def godot_to_blender_arm(gx, gy, gz):
    bx = gx + 0.36
    bz = gy + 0.33
    by = -gz + 0.13
    return Vector((bx, by, bz))

def blender_arm_to_godot(v):
    gx = v.x - 0.36
    gy = v.z - 0.33
    gz = -(v.y - 0.13)
    return Vector((gx, gy, gz))

# Target rim points in Godot:
# 10 o clock rim center: (-0.5029, 0.8648, -0.3849)
# Knuckle target (top/front of rim): (-0.500, 0.875, -0.380)
target_knuckle_L_godot = Vector((-0.500, 0.875, -0.380))
target_knuckle_L_blender = godot_to_blender_arm(target_knuckle_L_godot.x, target_knuckle_L_godot.y, target_knuckle_L_godot.z)

print("Target knuckle L in Godot:  ", target_knuckle_L_godot)
print("Target knuckle L in Blender:", target_knuckle_L_blender)

# Base spine rotations
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

bpy.context.view_layer.update()

# Let's test a range of arm and hand rotations for Left Arm
best_err = 999.0
best_params = None

# Current params:
# UpperArm.L: (-72.0, -25.2, -23.0)
# LowerArm.L: (0.0, 27.9, -50.9)
# Hand.L:     (-25.4, 47.0, 31.4)

# Grid search around current with wider variations
for ua_x in [-76.0, -72.0, -68.0, -64.0, -60.0]:
    for ua_y in [-30.0, -25.0, -20.0, -15.0]:
        for ua_z in [-30.0, -23.0, -15.0, -8.0]:
            for la_y in [15.0, 25.0, 35.0, 45.0]:
                for la_z in [-60.0, -50.0, -40.0, -30.0]:
                    pb_ua = arm.pose.bones["UpperArm.L"]
                    pb_la = arm.pose.bones["LowerArm.L"]
                    pb_h  = arm.pose.bones["Hand.L"]
                    
                    pb_ua.rotation_quaternion = Euler((math.radians(ua_x), math.radians(ua_y), math.radians(ua_z)), 'XYZ').to_quaternion()
                    pb_la.rotation_quaternion = Euler((math.radians(0.0), math.radians(la_y), math.radians(la_z)), 'XYZ').to_quaternion()
                    
                    # For Hand.L, find rotation that places Index2.L closest to target
                    # Hand wrist position is fixed once UA and LA are set
                    bpy.context.view_layer.update()
                    wrist_pos = pb_h.head
                    wrist_godot = blender_arm_to_godot(wrist_pos)
                    
                    # Wrist should be within 12cm of target knuckle
                    dist_w = (target_knuckle_L_godot - wrist_godot).length
                    if dist_w > 0.14 or dist_w < 0.05:
                        continue
                        
                    for h_x in [-35.0, -20.0, -10.0, 0.0, 10.0, 20.0]:
                        for h_y in [10.0, 25.0, 40.0, 55.0]:
                            for h_z in [-10.0, 5.0, 20.0, 35.0]:
                                pb_h.rotation_quaternion = Euler((math.radians(h_x), math.radians(h_y), math.radians(h_z)), 'XYZ').to_quaternion()
                                bpy.context.view_layer.update()
                                
                                idx2_pos = arm.pose.bones["Index2.L"].head
                                idx2_godot = blender_arm_to_godot(idx2_pos)
                                err = (target_knuckle_L_godot - idx2_godot).length
                                
                                if err < best_err:
                                    best_err = err
                                    best_params = {
                                        "UpperArm.L": (ua_x, ua_y, ua_z),
                                        "LowerArm.L": (0.0, la_y, la_z),
                                        "Hand.L":     (h_x, h_y, h_z),
                                        "wrist_godot": wrist_godot,
                                        "idx2_godot": idx2_godot,
                                        "err_cm": err * 100.0
                                    }

print("\n=== OPTIMIZATION RESULT ===")
print("Best knuckle error: ", best_err * 100.0, " cm")
if best_params:
    print("UpperArm.L:  ", best_params["UpperArm.L"])
    print("LowerArm.L:  ", best_params["LowerArm.L"])
    print("Hand.L:      ", best_params["Hand.L"])
    print("Wrist Godot: ", best_params["wrist_godot"])
    print("Knuckle Godot:", best_params["idx2_godot"])
