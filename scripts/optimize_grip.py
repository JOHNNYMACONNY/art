import bpy, math
from mathutils import Vector, Euler, Matrix, Quaternion

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')

# Target in Blender coordinates (runner root at (0,0,0)):
# Torus rim at 10 o'clock:
# X = +0.143
# Y = -0.445
# Z = +1.195
target_rim_l = Vector((0.143, -0.445, 1.195))
target_rim_r = Vector((-0.143, -0.445, 1.195))

# Baseline body rotations from add_car_drive_anim.py
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

bpy.context.view_layer.update()

# Let's grid search UpperArm.L, LowerArm.L, Hand.L rotations
best_dist = 999.0
best_angles = None

# We know arm needs to reach forward (-Y) and up (+Z) to target (0.143, -0.445, 1.195)
# Let's search over realistic shoulder, elbow, wrist ranges
for ua_x in range(-75, -50, 3):
    for ua_y in range(-35, -5, 5):
        for ua_z in range(-45, -15, 5):
            pb_ua = arm.pose.bones['UpperArm.L']
            pb_ua.rotation_quaternion = Euler((math.radians(ua_x), math.radians(ua_y), math.radians(ua_z)), 'XYZ').to_quaternion()
            
            for la_z in range(-70, -30, 5):
                for la_x in range(-20, 20, 10):
                    pb_la = arm.pose.bones['LowerArm.L']
                    pb_la.rotation_quaternion = Euler((math.radians(la_x), 0.0, math.radians(la_z)), 'XYZ').to_quaternion()
                    
                    for h_x in range(-20, 40, 10):
                        for h_y in range(-40, 20, 15):
                            for h_z in range(-20, 40, 15):
                                pb_h = arm.pose.bones['Hand.L']
                                pb_h.rotation_quaternion = Euler((math.radians(h_x), math.radians(h_y), math.radians(h_z)), 'XYZ').to_quaternion()
                                bpy.context.view_layer.update()
                                
                                # We want Hand.L tail (the knuckles) to be right at target_rim_l
                                hand_tail = arm.matrix_world @ pb_h.tail
                                d = (hand_tail - target_rim_l).length
                                if d < best_dist:
                                    best_dist = d
                                    best_angles = (ua_x, ua_y, ua_z, la_x, la_z, h_x, h_y, h_z)

print(f"Best distance to 10 o'clock rim: {best_dist*100:.2f} cm")
print(f"Best angles: {best_angles}")

