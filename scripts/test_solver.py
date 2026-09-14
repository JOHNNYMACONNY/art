import bpy
import math
from mathutils import Matrix, Vector, Euler

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='godot/models/runner.glb')
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm

# Let us verify the exact Blender -> Godot transformation matrix:
# 1. Armature local bone head: v_blender (X, Y, Z)
# 2. glTF export converts: X_gltf = X_blender, Y_gltf = Z_blender, Z_gltf = -Y_blender
# 3. Model node in runner.tscn has Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1):
#    X_runner = -X_gltf = -X_blender
#    Y_runner = Y_gltf = Z_blender
#    Z_runner = -Z_gltf = Y_blender
# 4. Runner is placed at (-0.36, -0.33, 0.13) in Coupe:
#    X_godot = -0.36 + X_runner = -0.36 - X_blender
#    Y_godot = -0.33 + Y_runner = -0.33 + Z_blender
#    Z_godot =  0.13 + Z_runner =  0.13 + Y_blender

def b_to_g(v):
    return Vector((-0.36 - v.x, -0.33 + v.z, 0.13 + v.y))

# Let us test this against current Hand.L and Index2.L:
# In previous diagnose_hands_mesh.gd:
# Hand.L:     (-0.4716, 0.8972, -0.3724)
# Index2.L:   (-0.4696, 0.7835, -0.4733)

# If X_godot = -0.4716 => X_blender = -0.36 - (-0.4716) = +0.1116
# If Y_godot = 0.8972  => Z_blender = 0.8972 - (-0.33)  = +1.2272
# If Z_godot = -0.3724 => Y_blender = -0.3724 - 0.13   = -0.5024

print("Predicted Blender coordinates for 10 o clock rim target:")
# 10 o clock rim target in Godot: (-0.5029, 0.8648, -0.3849)
target_godot = Vector((-0.5029, 0.8648, -0.3849))
target_blender = Vector((-0.36 - target_godot.x, target_godot.z - 0.13, target_godot.y + 0.33))
print("Target Godot:  ", target_godot)
print("Target Blender:", target_blender)
print("Verify inverse:", b_to_g(target_blender))
