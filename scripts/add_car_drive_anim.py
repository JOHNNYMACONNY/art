import bpy
import math
from mathutils import Quaternion, Euler, Vector

print("=== GENERATING AUTOMOTIVE DRIVING & STEERING ANIMATIONS IN RUNNER.GLB ===")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

# 1. Clean up any previous car actions and NLA tracks
for act in list(bpy.data.actions):
    if 'car_' in act.name:
        bpy.data.actions.remove(act)

if arm.animation_data:
    for tr in list(arm.animation_data.nla_tracks):
        arm.animation_data.nla_tracks.remove(tr)

# Automotive Power Grip (Curled fingers clenched around 3cm cylindrical steering wheel rim)
# In Mixamo armature, rotating around local -X curls fingers around rim
FINGER_GRIP_ROTATIONS = {
    # Left Hand (Wrapped around 10 o'clock wheel rim)
    "Index2.L":  (-60.0, 0.0, 0.0),
    "Index3.L":  (-75.0, 0.0, 0.0),
    "Index4.L":  (-55.0, 0.0, 0.0),

    "Middle2.L": (-62.0, 0.0, 0.0),
    "Middle3.L": (-78.0, 0.0, 0.0),
    "Middle4.L": (-55.0, 0.0, 0.0),

    "Ring2.L":   (-60.0, 0.0, 0.0),
    "Ring3.L":   (-75.0, 0.0, 0.0),
    "Ring4.L":   (-52.0, 0.0, 0.0),

    "Pinky2.L":  (-58.0, 0.0, 0.0),
    "Pinky3.L":  (-72.0, 0.0, 0.0),
    "Pinky4.L":  (-48.0, 0.0, 0.0),

    # Right Hand (Wrapped around 2 o'clock wheel rim)
    "Index2.R":  (-60.0, 0.0, 0.0),
    "Index3.R":  (-75.0, 0.0, 0.0),
    "Index4.R":  (-55.0, 0.0, 0.0),

    "Middle2.R": (-62.0, 0.0, 0.0),
    "Middle3.R": (-78.0, 0.0, 0.0),
    "Middle4.R": (-55.0, 0.0, 0.0),

    "Ring2.R":   (-60.0, 0.0, 0.0),
    "Ring3.R":   (-75.0, 0.0, 0.0),
    "Ring4.R":   (-52.0, 0.0, 0.0),

    "Pinky2.R":  (-58.0, 0.0, 0.0),
    "Pinky3.R":  (-72.0, 0.0, 0.0),
    "Pinky4.R":  (-48.0, 0.0, 0.0),
}

# Base Automotive Driving Posture (SAE J1100 / GTA-standard ergonomics)
BASE_BODY_ROTATIONS = {
    "Hips":       (-6.0, 0.0, 0.0),
    "Abdomen":    (-4.0, 0.0, 0.0),
    "Torso":      (-3.0, 0.0, 0.0),
    "Chest":      (-2.0, 0.0, 0.0),
    "Neck":       (8.0, 0.0, 0.0),
    "Head":       (7.0, 0.0, 0.0),

    # Arms pronated and reaching to standardized 36cm steering wheel (10-and-2 rim grip)
    "UpperArm.L": (-70.5, -25.4, -24.1),
    "LowerArm.L": (0.0, 58.2, -27.2),
    "Hand.L":     (16.1, 20.4, 12.4),
    "Thumb2.L":   (-20.0, 20.0, 50.0),
    "Thumb3.L":   (0.0, 0.0, 0.0),

    "UpperArm.R": (-66.0, 41.8, 34.2),
    "LowerArm.R": (0.0, -47.8, 6.2),
    "Hand.R":     (7.5, -19.0, -7.2),
    "Thumb2.R":   (10.0, 20.0, -50.0),
    "Thumb3.R":   (0.0, 0.0, 0.0),

    # Seated legs forward into footwell toward pedals
    "UpperLeg.L": (-74.0, 6.0, -8.0),
    "LowerLeg.L": (82.0, 0.0, 0.0),
    "Foot.L":     (-40.0, 0.0, 6.0),

    "UpperLeg.R": (-74.0, -6.0, 8.0),
    "LowerLeg.R": (82.0, 0.0, 0.0),
    "Foot.R":     (-40.0, 0.0, -6.0),
}

# Left turn: CCW wheel rotation on 36cm rim
STEER_LEFT_DELTAS = {
    "Torso":      (0.0, -3.0, -4.0),
    "Chest":      (0.0, -2.0, -3.0),
    "Head":       (0.0, 0.0, 6.0),

    # Left arm pulls down along rim
    "UpperArm.L": (6.0, 3.0, 4.0),
    "LowerArm.L": (0.0, -4.0, -6.0),
    "Hand.L":     (-4.0, -2.0, 4.0),

    # Right arm sweeps up across top of rim
    "UpperArm.R": (-8.0, -4.0, -8.0),
    "LowerArm.R": (0.0, 4.0, -6.0),
    "Hand.R":     (6.0, 4.0, -4.0),
}

# Right turn: CW wheel rotation on 36cm rim
STEER_RIGHT_DELTAS = {
    "Torso":      (0.0, 3.0, 4.0),
    "Chest":      (0.0, 2.0, 3.0),
    "Head":       (0.0, 0.0, -6.0),

    # Left arm sweeps up across top of rim
    "UpperArm.L": (-8.0, 4.0, 8.0),
    "LowerArm.L": (0.0, 4.0, 6.0),
    "Hand.L":     (6.0, -4.0, 4.0),

    # Right arm pulls down along rim
    "UpperArm.R": (6.0, -3.0, -4.0),
    "LowerArm.R": (0.0, -4.0, 6.0),
    "Hand.R":     (-4.0, 2.0, -4.0),
}

def create_driving_action(action_name, deltas):
    act = bpy.data.actions.new(name=action_name)
    arm.animation_data.action = act

    # 60 frames (2.0 sec at 30 fps) loop
    for f in [0, 15, 30, 45, 60]:
        t = f / 60.0 * 2.0 * math.pi
        breath = math.sin(t) * 0.003
        vibe = math.sin(t * 8.0) * 0.001

        pb_hips = arm.pose.bones.get("Hips")
        if pb_hips:
            pb_hips.location = Vector((0.0, 0.0, breath * 0.5))
            pb_hips.keyframe_insert(data_path="location", frame=f)

        # Apply body rotations + steering deltas
        all_rots = {**BASE_BODY_ROTATIONS, **FINGER_GRIP_ROTATIONS}
        for bname, (rx, ry, rz) in all_rots.items():
            pb = arm.pose.bones.get(bname)
            if not pb:
                continue

            d = deltas.get(bname, (0.0, 0.0, 0.0))
            cur_rx = rx + d[0]
            cur_ry = ry + d[1]
            cur_rz = rz + d[2]

            # Subtle engine rumble and breathing
            if bname in ["Chest", "Torso"]:
                cur_rx += math.sin(t) * 0.8
            elif bname == "Head":
                cur_ry += math.sin(t * 0.5) * 0.4
                cur_rx -= math.sin(t) * 0.3

            q = Euler((math.radians(cur_rx), math.radians(cur_ry), math.radians(cur_rz)), 'XYZ').to_quaternion()
            pb.rotation_quaternion = q
            pb.keyframe_insert(data_path="rotation_quaternion", frame=f)

    for fc in act.fcurves:
        for kp in fc.keyframe_points:
            kp.interpolation = 'BEZIER'

    return act

# Generate the three driving actions
car_drive_act = create_driving_action('car_drive_CharacterArmature', {})
car_steer_l_act = create_driving_action('car_steer_left_CharacterArmature', STEER_LEFT_DELTAS)
car_steer_r_act = create_driving_action('car_steer_right_CharacterArmature', STEER_RIGHT_DELTAS)

# Push all desired actions to NLA tracks
all_actions = [
    bpy.data.actions.get('idle_CharacterArmature'),
    bpy.data.actions.get('walk_CharacterArmature'),
    bpy.data.actions.get('run_CharacterArmature'),
    bpy.data.actions.get('bike_ride_CharacterArmature'),
    car_drive_act,
    car_steer_l_act,
    car_steer_r_act
]

for act in all_actions:
    if act:
        track = arm.animation_data.nla_tracks.new()
        track.name = act.name.replace("_CharacterArmature", "")
        strip = track.strips.new(track.name, 0, act)
        strip.action = act

out_glb = 'godot/models/runner.glb'
bpy.ops.export_scene.gltf(
    filepath=out_glb,
    export_format='GLB',
    export_animations=True,
    export_nla_strips=True,
    export_def_bones=True
)
print("Successfully exported runner.glb with car_drive, car_steer_left, and car_steer_right!")
