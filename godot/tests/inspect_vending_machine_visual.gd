extends SceneTree

const OUT_DIR := "res://../docs/visual_direction/references"

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    print("=== INSPECTING VENDING MACHINE 3D MODEL & TEXTURES ===")
    
    # 1. Load GLB directly
    var glb_packed := load("res://models/prop_vending_machine.glb") as PackedScene
    if not glb_packed:
        printerr("Failed to load prop_vending_machine.glb")
        quit(1)
        return
        
    var glb_inst := glb_packed.instantiate() as Node3D
    print("GLB root node:", glb_inst.name)
    
    var mesh_instances := _find_mesh_instances(glb_inst)
    print("Found MeshInstance3D count:", mesh_instances.size())
    
    for mi in mesh_instances:
        print("MeshInstance:", mi.name, "visible:", mi.visible)
        var mesh := mi.mesh
        if not mesh:
            print("  No mesh attached!")
            continue
        print("  Surface count:", mesh.get_surface_count())
        for s in range(mesh.get_surface_count()):
            var mat := mesh.surface_get_material(s)
            var mat_name := mat.resource_name if mat else "null"
            var arrays := mesh.surface_get_arrays(s)
            var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
            
            var min_uv := Vector2(9999, 9999)
            var max_uv := Vector2(-9999, -9999)
            for uv in uvs:
                min_uv.x = min(min_uv.x, uv.x)
                min_uv.y = min(min_uv.y, uv.y)
                max_uv.x = max(max_uv.x, uv.x)
                max_uv.y = max(max_uv.y, uv.y)
                
            print("  Surface ", s, ": mat=", mat_name, " verts=", verts.size(), " uvs=", uvs.size(), " uv_bounds=[", min_uv, " -> ", max_uv, "]")
            if mat is StandardMaterial3D:
                var std_mat := mat as StandardMaterial3D
                var tex := std_mat.albedo_texture
                print("    StandardMaterial3D albedo_color=", std_mat.albedo_color, " tex=", tex.resource_path if tex else "none", " trans=", std_mat.transparency)

    glb_inst.queue_free()
    
    # 2. Load PackedScene prop_vending_machine.tscn
    var tscn_packed := load("res://scenes/props/prop_vending_machine.tscn") as PackedScene
    var scene_inst := tscn_packed.instantiate() as Node3D
    root.add_child(scene_inst)
    
    # Setup camera and environment for capture
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.08, 0.09, 0.11, 1.0)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.65, 0.68, 0.72, 1.0)
    env.ambient_light_energy = 1.2
    env_node.environment = env
    root.add_child(env_node)
    
    # Key light
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-35.0, 30.0, 0.0)
    sun.light_color = Color(1.0, 0.98, 0.92, 1.0)
    sun.light_energy = 1.6
    sun.shadow_enabled = true
    root.add_child(sun)
    
    # Fill light
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-15.0, -150.0, 0.0)
    fill.light_color = Color(0.55, 0.65, 0.85, 1.0)
    fill.light_energy = 0.8
    root.add_child(fill)
    
    var cam := Camera3D.new()
    cam.fov = 30.0
    root.add_child(cam)
    cam.make_current()
    
    # Let frames settle
    for i in range(15):
        await process_frame
        
    var dir := ProjectSettings.globalize_path(OUT_DIR)
    
    # Camera View 1: Direct Front Elevation
    var center := Vector3(0.0, 1.0, 0.0)
    cam.position = Vector3(0.0, 1.0, -3.6)
    cam.look_at(center, Vector3.UP)
    for i in range(10):
        await process_frame
    var img := root.get_viewport().get_texture().get_image()
    img.save_png(dir + "/render_vending_machine_front.png")
    print("Saved render_vending_machine_front.png")
    
    # Camera View 2: Isometric 3/4 Perspective
    var pitch := deg_to_rad(22.0)
    var yaw := deg_to_rad(-140.0)
    var dist := 3.8
    cam.position = center + Vector3(sin(yaw) * cos(pitch) * dist, sin(pitch) * dist, cos(yaw) * cos(pitch) * dist)
    cam.look_at(center, Vector3.UP)
    for i in range(10):
        await process_frame
    img = root.get_viewport().get_texture().get_image()
    img.save_png(dir + "/render_vending_machine_iso.png")
    print("Saved render_vending_machine_iso.png")

    # Camera View 3: Close-up on Marquee Header
    var marquee_center := Vector3(0.0, 1.80, -0.45)
    cam.position = marquee_center + Vector3(0.0, 0.05, -1.8)
    cam.look_at(marquee_center, Vector3.UP)
    for i in range(10):
        await process_frame
    img = root.get_viewport().get_texture().get_image()
    img.save_png(dir + "/render_vending_machine_marquee.png")
    print("Saved render_vending_machine_marquee.png")

    # Camera View 4: Close-up on Keypad & Display Window
    var mid_center := Vector3(0.05, 1.15, -0.45)
    cam.position = mid_center + Vector3(0.0, 0.0, -1.9)
    cam.look_at(mid_center, Vector3.UP)
    for i in range(10):
        await process_frame
    img = root.get_viewport().get_texture().get_image()
    img.save_png(dir + "/render_vending_machine_mid.png")
    print("Saved render_vending_machine_mid.png")

    print("Visual inspection capture complete.")
    quit(0)

func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
    var result: Array[MeshInstance3D] = []
    if node is MeshInstance3D:
        result.append(node as MeshInstance3D)
    for c in node.get_children():
        result.append_array(_find_mesh_instances(c))
    return result
