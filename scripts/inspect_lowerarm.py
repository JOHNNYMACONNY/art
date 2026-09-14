import bpy
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]

b_la_l = arm.data.bones.get("LowerArm.L")
b_la_r = arm.data.bones.get("LowerArm.R")

print("LowerArm.L rest matrix:\n", b_la_l.matrix_local)
print("LowerArm.R rest matrix:\n", b_la_r.matrix_local)

