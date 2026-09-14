"""
blender_import_library_refs.py
Imports CC0 library vehicle meshes as wireframe ghost overlays in Blender.
Sources (CC0 1.0):
  - Quaternius Police Car  (poly.pizza/m/BwwnUrWGmV)
  - Quaternius Sports Car  (poly.pizza/m/1mkmFkAz5v)
  - Kenney Car Kit garbage-truck.fbx  (kenney.nl/assets/car-kit)
Usage: blender -b --python scripts/blender_import_library_refs.py
"""
import bpy, os, math

PROJ = "/Users/bobbyinthelobby/{art"
LIB  = os.path.join(PROJ, "assets/library_meshes/quaternius")
OUT  = os.path.join(PROJ, "docs/visual_direction/references")

def reset_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

def import_glb_as_wire(filepath, name, location=(0,0,0), scale=1.0):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=filepath)
    new_obs = set(bpy.data.objects) - before
    for ob in new_obs:
        ob.name = f"REF_{name}_{ob.name}"
        ob.location = location
        ob.scale = (scale, scale, scale)
        if ob.type == 'MESH':
            ob.display_type = 'WIRE'
            ob.show_in_front = True
    print(f"[REF] Imported {len(new_obs)} objs for {name}")
    return list(new_obs)

def import_fbx_as_wire(filepath, name, location=(0,0,0), scale=1.0):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=filepath)
    new_obs = set(bpy.data.objects) - before
    for ob in new_obs:
        ob.name = f"REF_{name}_{ob.name}"
        ob.location = location
        ob.scale = (scale, scale, scale)
        if ob.type == 'MESH':
            ob.display_type = 'WIRE'
            ob.show_in_front = True
    print(f"[REF] Imported FBX {len(new_obs)} objs for {name}")
    return list(new_obs)

def setup_camera(axis='SIDE'):
    cam_data = bpy.data.cameras.new("RefCam")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = 8.0
    cam = bpy.data.objects.new("RefCam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    if axis == 'SIDE':
        cam.location = (0, -12, 1.2)
        cam.rotation_euler = (math.radians(90), 0, 0)
    return cam

if __name__ == "__main__":
    reset_scene()

    police_path = os.path.join(LIB, "police_car.glb")
    import_glb_as_wire(police_path, "PoliceCar", location=(5.0, 0, 0), scale=1.0)

    sports_path = os.path.join(LIB, "sports_car.glb")
    import_glb_as_wire(sports_path, "SportsCar", location=(-5.0, 0, 0), scale=1.0)

    truck_path = os.path.join(LIB, "garbage_truck_kenney.fbx")
    import_fbx_as_wire(truck_path, "GarbageTruck", location=(0, 0, 0), scale=0.01)

    setup_camera(axis='SIDE')

    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
    scene.render.image_settings.file_format = 'PNG'
    scene.render.filepath = os.path.join(OUT, "library_ref_side.png")
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 540
    bpy.ops.render.render(write_still=True)

    blend_out = os.path.join(PROJ, "models_source/library_refs.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_out)
    print(f"[DONE] Saved: {blend_out}")
    print("[OPEN] models_source/library_refs.blend to model against ghosts")
