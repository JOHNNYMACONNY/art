import bpy
import math
from mathutils import Vector, Euler, Quaternion

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

BASE_BODY_ROTATIONS = {
    "Hips":       (-6.0, 0.0, 0.0),
    "Abdomen":    (-4.0, 0.0, 0.0),
    "Torso":      (-3.0, 0.0, 0.0),
    "Chest":      (-2.0, 0.0, 0.0),
    "Neck":       (0.0, 0.0, 0.0),
    "Head":       (15.0, 0.0, 0.0),

    # Arms pronated and reaching to standardized 36cm steering wheel (10-and-2 rim grip)
    "UpperArm.L": (-72.0, -25.2, -23.0),
    "LowerArm.L": (0.0, 27.9, -50.9),
    "Hand.L":     (-25.4, 47.0, 31.4),
    "Thumb2.L":   (-30.0, 10.0, 15.0),
    "Thumb3.L":   (-40.0, 0.0, 10.0),

    "UpperArm.R": (-72.0, 25.2, 23.0),
    "LowerArm.R": (0.0, -27.9, 50.9),
    "Hand.R":     (-25.4, -47.0, -31.4),
    "Thumb2.R":   (-25.0, -10.0, -15.0),
    "Thumb3.R":   (-35.0, 0.0, -10.0),
}

for bname, (rx, ry, rz) in BASE_BODY_ROTATIONS.items():
    pb = arm.pose.bones.get(bname)
    if pb:
        q = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), 'XYZ').to_quaternion()
        pb.rotation_quaternion = q

bpy.context.view_layer.update()

print("\n--- CURRENT POSED BONE WORLD POSITIONS IN BLENDER ---")
target_L = Vector((0.1429, -0.5149, 1.1948))
target_R = Vector((-0.1429, -0.5149, 1.1948))
print(f"Target Left Knuckle:  {target_L}")
print(f"Target Right Knuckle: {target_R}")

for side in ["L", "R"]:
    print(f"\n[{side} SIDE]")
    for b in ["UpperArm", "LowerArm", "Hand", "Index2", "Thumb2", "Thumb3"]:
        pb = arm.pose.bones.get(f"{b}.{side}")
        if pb:
            # pb.head is in armature space (arm.matrix_world * pb.head is world)
            w_head = arm.matrix_world @ pb.head
            print(f"  {b}.{side:2s} head in arm_space: {pb.head} | world: {w_head}")
            if b == "Index2":
                tgt = target_L if side == "L" else target_R
                dist = (pb.head - tgt).length
                dist_w = (w_head - tgt).length
                print(f"    Index2.{side} dist to tgt: arm_space={dist:.4f}m, world={dist_w:.4f}m")
