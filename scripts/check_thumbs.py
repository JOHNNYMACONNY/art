import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]

for side in ["L", "R"]:
    print(f"\nThumb bones for {side}:")
    for b in arm.pose.bones:
        if "Thumb" in b.name and b.name.endswith(f".{side}"):
            print(f"  {b.name}")
