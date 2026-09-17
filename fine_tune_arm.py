import bpy, math
from mathutils import Vector, Euler, Matrix

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')

# In Godot space:
# Wheel mount is (-0.36, 0.79, -0.35)
# Left rim 10 o'clock: (-0.477, 0.896, -0.399)
# In Godot, runner is at seat + Vector3(0.0, -0.78, 0.18)
# So relative to runner root in Godot:
# Seat is at (0, 0.78, -0.18)
# Wheel mount is at (0, 0.78 + 0.34, -0.18 - 0.30) = (0, 1.12, -0.48)
# Left rim 10 o'clock: (-0.117, 1.12 + 0.075, -0.48 + 0.035) = (-0.117, 1.195, -0.445)
# In Blender, Godot (+X, +Y, +Z) corresponds to Blender (-X, -Z, +Y):
# Godot X = -0.117 -> Blender X = +0.117
# Godot Y = +1.195 -> Blender Z = +1.195
# Godot Z = -0.445 -> Blender Y = -0.445
target_godot_left_rim = Vector((-0.117, 1.195, -0.445))
target_blender_left_rim = Vector((0.117, -0.445, 1.195))

BASE_BODY_ROTATIONS = {
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

for bname, (rx, ry, rz) in BASE_BODY_ROTATIONS.items():
    pb = arm.pose.bones.get(bname)
    if pb:
        pb.rotation_mode = 'QUATERNION'
        pb.rotation_quaternion = Euler((math.radians(rx), math.radians(ry), math.radians(rz)), 'XYZ').to_quaternion()

pb_ua = arm.pose.bones['UpperArm.L']
pb_la = arm.pose.bones['LowerArm.L']
pb_h = arm.pose.bones['Hand.L']
pb_i2 = arm.pose.bones['Index2.L']
pb_i3 = arm.pose.bones['Index3.L']
pb_i4 = arm.pose.bones['Index4.L']
pb_t2 = arm.pose.bones['Thumb2.L']
pb_t3 = arm.pose.bones['Thumb3.L']

# Fast search around base:
best_dist = 999.0
best = None

for ua_x in range(-76, -58, 2):
    for ua_y in range(-30, -10, 3):
        for ua_z in range(-38, -18, 3):
            pb_ua.rotation_quaternion = Euler((math.radians(ua_x), math.radians(ua_y), math.radians(ua_z)), 'XYZ').to_quaternion()
            for la_z in range(-55, -30, 3):
                pb_la.rotation_quaternion = Euler((0.0, 0.0, math.radians(la_z)), 'XYZ').to_quaternion()
                for h_x in range(-15, 25, 5):
                    for h_y in range(-25, 15, 5):
                        for h_z in range(-20, 20, 5):
                            pb_h.rotation_quaternion = Euler((math.radians(h_x), math.radians(h_y), math.radians(h_z)), 'XYZ').to_quaternion()
                            bpy.context.view_layer.update()
                            
                            pos = arm.matrix_world @ pb_h.tail
                            d = (pos - target_blender_left_rim).length
                            if d < best_dist:
                                best_dist = d
                                best = (ua_x, ua_y, ua_z, la_z, h_x, h_y, h_z)

print(f"Best distance: {best_dist*100:.2f} cm")
print(f"Best: UpperArm.L=({best[0]}, {best[1]}, {best[2]}), LowerArm.L=(0, 0, {best[3]}), Hand.L=({best[4]}, {best[5]}, {best[6]})")

