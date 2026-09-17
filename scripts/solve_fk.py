import bpy
import math
from mathutils import Euler, Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

# Target in Godot:
# Rim center at 10 o clock: (-0.5029, 0.8648, -0.3849)
# Rim center at 2 o clock:  (-0.2171, 0.8648, -0.3849)

# Base spine rotations
SPINE_ROTS = {
    "Hips":       (-6.0, 0.0, 0.0),
    "Abdomen":    (-4.0, 0.0, 0.0),
    "Torso":      (-3.0, 0.0, 0.0),
    "Chest":      (-2.0, 0.0, 0.0),
    "Head":       (15.0, 0.0, 0.0),
}

def eval_arm(ua_rot, la_rot, h_rot, side="L"):
    for bname, (rx, ry, rz) in SPINE_ROTS.items():
        pb = arm.pose.bones.get(bname)
        if pb:
            pb.rotation_quaternion = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), 'XYZ').to_quaternion()

    pb_ua = arm.pose.bones[f"UpperArm.{side}"]
    pb_la = arm.pose.bones[f"LowerArm.{side}"]
    pb_h  = arm.pose.bones[f"Hand.{side}"]
    
    pb_ua.rotation_quaternion = Euler((math.radians(ua_rot[0]), math.radians(ua_rot[1]), math.radians(ua_rot[2])), 'XYZ').to_quaternion()
    pb_la.rotation_quaternion = Euler((math.radians(la_rot[0]), math.radians(la_rot[1]), math.radians(la_rot[2])), 'XYZ').to_quaternion()
    pb_h.rotation_quaternion  = Euler((math.radians(h_rot[0]),  math.radians(h_rot[1]),  math.radians(h_rot[2])),  'XYZ').to_quaternion()
    
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    arm_eval = arm.evaluated_get(dg)
    
    p_h = arm_eval.pose.bones[f"Hand.{side}"].head
    p_idx2 = arm_eval.pose.bones[f"Index2.{side}"].head
    p_idx3 = arm_eval.pose.bones[f"Index3.{side}"].head
    p_idx4e = arm_eval.pose.bones[f"Index4.{side}_end"].tail if f"Index4.{side}_end" in arm_eval.pose.bones else arm_eval.pose.bones[f"Index4.{side}"].tail
    p_t3 = arm_eval.pose.bones[f"Thumb3.{side}"].head
    
    return p_h, p_idx2, p_idx3, p_idx4e, p_t3

# Test current Left Arm
p_h, p_idx2, p_idx3, p_idx4e, p_t3 = eval_arm((-72.0, -25.2, -23.0), (0.0, 27.9, -50.9), (-25.4, 47.0, 31.4), "L")
print("CURRENT LEFT ARM:")
print("Hand.L:     ", p_h)
print("Index2.L:   ", p_idx2)
print("Index4e.L:  ", p_idx4e)
print("Thumb3.L:   ", p_t3)
