import bpy
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]

b_ua_l = arm.data.bones.get("UpperArm.L")
b_ua_r = arm.data.bones.get("UpperArm.R")

print("UpperArm.L rest matrix:\n", b_ua_l.matrix_local)
print("UpperArm.R rest matrix:\n", b_ua_r.matrix_local)

