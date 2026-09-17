import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]

b_h_l = arm.data.bones.get("Hand.L")
b_h_r = arm.data.bones.get("Hand.R")

print("Hand.L rest matrix:\n", b_h_l.matrix_local)
print("Hand.R rest matrix:\n", b_h_r.matrix_local)

