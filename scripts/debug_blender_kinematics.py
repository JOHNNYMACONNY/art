import bpy
import math
from mathutils import Vector, Euler, Quaternion

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

print("Armature object matrix_world:", arm.matrix_world)

# Check rest positions of bones
bones_to_check = [
    "Hips", "Spine", "Chest", "UpperArm.L", "LowerArm.L", "Hand.L", "Index1.L", "Index2.L", "Thumb1.L", "Thumb2.L", "Thumb3.L",
    "UpperArm.R", "LowerArm.R", "Hand.R", "Index1.R", "Index2.R", "Thumb1.R", "Thumb2.R", "Thumb3.R"
]

print("\n--- POSE BONE ROTATION MODES & HEADS ---")
for bname in bones_to_check:
    pb = arm.pose.bones.get(bname)
    if pb:
        print(f"{bname:12s} head={pb.head} tail={pb.tail} rot_mode={pb.rotation_mode}")

