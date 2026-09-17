import bpy
import math
from mathutils import Quaternion, Euler, Vector

print("=== TESTING BONE BAKE ===")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

# Clean old car actions
for act in list(bpy.data.actions):
    if 'car_' in act.name:
        bpy.data.actions.remove(act)

if arm.animation_data:
    for tr in list(arm.animation_data.nla_tracks):
        arm.animation_data.nla_tracks.remove(tr)

# Quaternions from Godot optimization:
# Godot Quat (x, y, z, w) -> Blender Quaternion((w, x, y, z))
q_ua_l = Quaternion((0.440269, -0.8618, 0.248237, 0.042933))
q_la_l = Quaternion((0.714631, 0.21901, 0.114007, -0.654477))
q_h_l  = Quaternion((0.385179, -0.409225, 0.522301, 0.641385))

# Symmetrical Right Arm:
# In Blender, mirror across X (invert y and z in quaternion or appropriate components):
# Godot: final_q_uar = Quaternion.from_euler(Vector3(deg_to_rad(best_ua.x), 0, deg_to_rad(-best_ua.z))) * cur_rot_uar
# Let us use Godot's exact symmetry calculation
EOF
