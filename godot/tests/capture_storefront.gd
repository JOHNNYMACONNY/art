extends SceneTree

const OUT_DIR := "/Users/bobbyinthelobby/{art/docs/visual_direction/references"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root_node.name = "StorefrontCaptureRoot"
	root.add_child(root_node)

	# World Environment (High-contrast graphic comic daylight, matching Candidate B concept sheet)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.72, 0.75, 0.74, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.68, 0.70, 0.72, 1.0)
	env.ambient_light_energy = 0.65
	env.glow_enabled = false
	env_node.environment = env
	root_node.add_child(env_node)

	# Key light (sun) - hard two-tone cel shadow cuts
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 42.0, 0.0)
	sun.light_color = Color(1.0, 0.97, 0.90, 1.0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	root_node.add_child(sun)

	# Cool fill light (softens harsh back-shadows on actors and props)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30.0, -138.0, 0.0)
	fill.light_color = Color(0.60, 0.68, 0.76, 1.0)
	fill.light_energy = 0.35
	root_node.add_child(fill)

	# Daylight ground bounce fill (illuminates under-awning facade and street details)
	var bounce := DirectionalLight3D.new()
	bounce.rotation_degrees = Vector3(15.0, -20.0, 0.0)
	bounce.light_color = Color(0.72, 0.74, 0.76, 1.0)
	bounce.light_energy = 0.45
	root_node.add_child(bounce)

	# Workshop Interior Ambient Warm Light (illuminates authentic illustrated backdrop)
	var shop_light := OmniLight3D.new()
	shop_light.position = Vector3(-1.6, 2.0, 1.2)
	shop_light.light_color = Color(1.0, 0.88, 0.65, 1.0)
	shop_light.light_energy = 0.75
	shop_light.omni_range = 4.5
	shop_light.shadow_enabled = false
	root_node.add_child(shop_light)

	var shop_light2 := OmniLight3D.new()
	shop_light2.light_energy = 0.0
	root_node.add_child(shop_light2)

	var deep_light := OmniLight3D.new()
	deep_light.light_energy = 0.0
	root_node.add_child(deep_light)

	var bay_fill := SpotLight3D.new()
	bay_fill.light_energy = 0.0
	root_node.add_child(bay_fill)

	# Fascia Sign Top Gooseneck Barn Lighting (disabled in daylight to avoid hotspot glare)
	var fascia_light := SpotLight3D.new()
	fascia_light.position = Vector3(0.0, 5.5, 3.8)
	fascia_light.light_color = Color(1.0, 0.96, 0.88, 1.0)
	fascia_light.light_energy = 0.0
	fascia_light.spot_range = 6.5
	fascia_light.spot_angle = 65.0
	fascia_light.shadow_enabled = false
	root_node.add_child(fascia_light)
	fascia_light.look_at(Vector3(0.0, 4.0, 2.7), Vector3.UP)

	# Side Wall Gooseneck Lamp Light (subtle warm accent in daylight)
	var side_lamp := OmniLight3D.new()
	side_lamp.position = Vector3(5.2, 4.0, 1.2)
	side_lamp.light_color = Color(1.0, 0.90, 0.72, 1.0)
	side_lamp.light_energy = 0.10
	side_lamp.omni_range = 6.0
	side_lamp.shadow_enabled = false
	root_node.add_child(side_lamp)

	# 1. Sidewalk slab (concrete, curb at Z=+6.7)
	var sidewalk := MeshInstance3D.new()
	var sw_box := BoxMesh.new()
	sw_box.size = Vector3(18.0, 0.15, 4.4)
	var sw_mat := StandardMaterial3D.new()
	sw_mat.albedo_color = Color(0.40, 0.42, 0.45, 1.0)
	sw_mat.roughness = 0.88
	sidewalk.mesh = sw_box
	sidewalk.material_override = sw_mat
	sidewalk.position = Vector3(0.0, 0.075, 4.5)
	root_node.add_child(sidewalk)

	# 1b. Sidewalk Beveled Curb Stone along roadway
	var curb := MeshInstance3D.new()
	var curb_box := BoxMesh.new()
	curb_box.size = Vector3(18.0, 0.16, 0.24)
	var curb_mat := StandardMaterial3D.new()
	curb_mat.albedo_color = Color(0.50, 0.52, 0.55, 1.0)
	curb_mat.roughness = 0.82
	curb.mesh = curb_box
	curb.material_override = curb_mat
	curb.position = Vector3(0.0, 0.08, 6.72)
	root_node.add_child(curb)

	# 1c. Storm Drainage Inlet Grate at curb
	var drain := MeshInstance3D.new()
	var drain_quad := QuadMesh.new()
	drain_quad.size = Vector2(1.3, 0.45)
	drain_quad.orientation = PlaneMesh.FACE_Y
	var drain_mat := StandardMaterial3D.new()
	drain_mat.albedo_color = Color(0.08, 0.09, 0.10, 1.0)
	drain_mat.roughness = 0.90
	drain.mesh = drain_quad
	drain.material_override = drain_mat
	drain.position = Vector3(-3.2, 0.015, 6.95)
	root_node.add_child(drain)

	# 2. Roadway plane (dark asphalt)
	var road := MeshInstance3D.new()
	var road_plane := PlaneMesh.new()
	road_plane.size = Vector2(32.0, 20.0)
	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.13, 0.14, 0.15, 1.0)
	road_mat.roughness = 0.92
	road.mesh = road_plane
	road.material_override = road_mat
	road.position = Vector3(0.0, 0.0, 15.0)
	root_node.add_child(road)

	# 3. Road Markings Decal ("GEARS DISTRICT GD-13")
	var road_marking := MeshInstance3D.new()
	var mark_mesh := QuadMesh.new()
	mark_mesh.size = Vector2(4.4, 3.6)
	mark_mesh.orientation = PlaneMesh.FACE_Y
	var mark_mat := StandardMaterial3D.new()
	var atlas_tex := load("res://textures/urban_clutter/tex_storefront_burnside.png") as Texture2D
	mark_mat.albedo_texture = atlas_tex
	mark_mat.uv1_scale = Vector3(348.0 / 2048.0, 428.0 / 2048.0, 1.0)
	mark_mat.uv1_offset = Vector3(1700.0 / 2048.0, 1620.0 / 2048.0, 0.0)
	mark_mat.roughness = 0.85
	road_marking.mesh = mark_mesh
	road_marking.material_override = mark_mat
	road_marking.position = Vector3(0.0, 0.02, 8.2)
	road_marking.rotation_degrees = Vector3.ZERO
	root_node.add_child(road_marking)

	# 3b. Dark Ink Contact Shadow Occlusion Skirts (AO Decals)
	var make_shadow := func(pos: Vector3, sz: Vector2) -> MeshInstance3D:
		var sh := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = sz
		q.orientation = PlaneMesh.FACE_Y
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.015, 0.015, 0.02, 0.75)
		m.roughness = 1.0
		sh.mesh = q
		sh.material_override = m
		sh.position = pos
		root_node.add_child(sh)
		return sh

	make_shadow.call(Vector3(0.0, 0.155, 0.0), Vector2(9.8, 5.8)) # building base
	make_shadow.call(Vector3(3.2, 0.155, 3.8), Vector2(1.4, 1.2)) # kiosk
	make_shadow.call(Vector3(-3.4, 0.155, 3.8), Vector2(2.6, 1.8)) # dumpster front
	make_shadow.call(Vector3(5.8, 0.155, -1.0), Vector2(1.8, 2.6)) # dumpster side
	make_shadow.call(Vector3(0.6, 0.155, 4.8), Vector2(2.2, 1.0)) # bike
	make_shadow.call(Vector3(-0.8, 0.155, 4.8), Vector2(0.9, 0.9)) # runner
	make_shadow.call(Vector3(-1.6, 0.155, 4.4), Vector2(1.1, 1.1)) # worker bot
	make_shadow.call(Vector3(2.0, 0.155, 4.2), Vector2(1.0, 0.8)) # crawler

	# 4. Burnside Storefront Building (Facade at Z=+2.7)
	var sf_scene := load("res://scenes/world/burnside_storefront.tscn") as PackedScene
	var sf := sf_scene.instantiate() as Node3D
	sf.position = Vector3(0.0, 0.15, 0.0)
	root_node.add_child(sf)

	# 5. Signal Quota Dispensary Kiosk (Right sidewalk)
	var kiosk_scene := load("res://scenes/props/prop_quota_kiosk.tscn") as PackedScene
	var kiosk := kiosk_scene.instantiate() as Node3D
	kiosk.position = Vector3(3.2, 0.15, 3.8)
	kiosk.rotation_degrees = Vector3(0.0, -15.0, 0.0)
	root_node.add_child(kiosk)

	# 6. Scrap Dumpster (Left sidewalk, overflowing with scrap)
	var dumpster_scene := load("res://scenes/props/prop_scrap_dumpster.tscn") as PackedScene
	var dumpster := dumpster_scene.instantiate() as Node3D
	dumpster.position = Vector3(-3.4, 0.15, 3.8)
	dumpster.rotation_degrees = Vector3(0.0, 8.0, 0.0)
	root_node.add_child(dumpster)

	# 7. Second Dumpster for Side Elevation (Placed on right brick wall, leaving left stencil unclipped per Panel C)
	var dumpster_side := dumpster_scene.instantiate() as Node3D
	dumpster_side.position = Vector3(5.8, 0.15, -1.0)
	dumpster_side.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	root_node.add_child(dumpster_side)

	# 8. Surveillance Utility Pole (Curb corner)
	var pole_scene := load("res://scenes/props/prop_utility_pole.tscn") as PackedScene
	var pole := pole_scene.instantiate() as Node3D
	pole.position = Vector3(-5.2, 0.15, 6.4)
	pole.rotation_degrees = Vector3(0.0, 30.0, 0.0)
	root_node.add_child(pole)

	# SCRAP HEAP: Critical secondary silhouette element at NW street corner (Defect 1 fix)
	# Stacked irregular scrap chunks, ~1.4m tall, draws player eye to entrance axis at 32° view
	var make_scrap_chunk := func(pos: Vector3, size: Vector3, rot_y: float) -> void:
		var chunk := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		var scrap_mat := StandardMaterial3D.new()
		scrap_mat.albedo_color = Color(0.22, 0.20, 0.18, 1.0)
		scrap_mat.roughness = 0.92
		scrap_mat.metallic = 0.35
		chunk.mesh = box
		chunk.material_override = scrap_mat
		chunk.position = pos
		chunk.rotation_degrees = Vector3(0.0, rot_y, 0.0)
		root_node.add_child(chunk)

	make_scrap_chunk.call(Vector3(-5.4, 0.22, 5.2), Vector3(1.1, 0.45, 0.80), 12.0)  # base layer
	make_scrap_chunk.call(Vector3(-5.6, 0.55, 5.0), Vector3(0.90, 0.38, 0.60), -8.0)
	make_scrap_chunk.call(Vector3(-5.3, 0.80, 4.8), Vector3(0.70, 0.35, 0.55), 22.0)  # mid tier
	make_scrap_chunk.call(Vector3(-5.5, 1.02, 5.1), Vector3(0.55, 0.28, 0.40), -14.0)
	make_scrap_chunk.call(Vector3(-5.2, 1.22, 4.9), Vector3(0.42, 0.22, 0.35), 5.0)   # peak ~1.4m
	# Yellow accent scrap (oil drum fragment)
	var drum_chunk := MeshInstance3D.new()
	var drum_cyl := CylinderMesh.new()
	drum_cyl.top_radius = 0.18
	drum_cyl.bottom_radius = 0.18
	drum_cyl.height = 0.55
	drum_cyl.radial_segments = 10
	var drum_mat := StandardMaterial3D.new()
	drum_mat.albedo_color = Color(0.88, 0.64, 0.08, 1.0)
	drum_mat.roughness = 0.72
	drum_chunk.mesh = drum_cyl
	drum_chunk.material_override = drum_mat
	drum_chunk.position = Vector3(-5.0, 0.43, 5.3)
	drum_chunk.rotation_degrees = Vector3(30.0, 0.0, 12.0)
	root_node.add_child(drum_chunk)
	# DEFECT 1 FIX: Rebar spikes protruding from heap crown for jagged silhouette punctuation
	var rebar_mat := StandardMaterial3D.new()
	rebar_mat.albedo_color = Color(0.18, 0.16, 0.14, 1.0)
	rebar_mat.roughness = 0.88
	rebar_mat.metallic = 0.55
	for spike_data in [
		[Vector3(-5.35, 1.50, 5.05), Vector3(0.0, 12.0, -22.0), 0.65],   # leaning left
		[Vector3(-5.15, 1.42, 4.95), Vector3(0.0, -8.0, 18.0), 0.80],    # leaning right tall
		[Vector3(-5.55, 1.35, 5.15), Vector3(0.0, 5.0, -32.0), 0.55],    # short left lean
		[Vector3(-5.25, 1.48, 5.08), Vector3(0.0, 22.0, 8.0), 0.70],     # near vertical
	]:
		var spike := MeshInstance3D.new()
		var scyl := CylinderMesh.new()
		scyl.top_radius = 0.018
		scyl.bottom_radius = 0.028
		scyl.height = spike_data[2]
		scyl.radial_segments = 6
		spike.mesh = scyl
		spike.material_override = rebar_mat
		spike.position = spike_data[0]
		spike.rotation_degrees = spike_data[1]
		root_node.add_child(spike)

	# Sagging overhead power cables spanning the street from utility pole to building
	var make_cable := func(start_p: Vector3, end_p: Vector3, sag: float, radius: float) -> void:
		var cable_mat := StandardMaterial3D.new()
		cable_mat.albedo_color = Color(0.02, 0.02, 0.03, 1.0)
		cable_mat.roughness = 0.95
		var seg_count := 14
		for s in range(seg_count):
			var t0 := float(s) / float(seg_count)
			var t1 := float(s + 1) / float(seg_count)
			var p0 := start_p.lerp(end_p, t0) + Vector3(0.0, -sag * 4.0 * t0 * (1.0 - t0), 0.0)
			var p1 := start_p.lerp(end_p, t1) + Vector3(0.0, -sag * 4.0 * t1 * (1.0 - t1), 0.0)
			var seg := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = radius
			cyl.bottom_radius = radius
			cyl.height = p0.distance_to(p1)
			cyl.radial_segments = 8
			seg.mesh = cyl
			seg.material_override = cable_mat
			seg.position = (p0 + p1) * 0.5
			var dir := (p1 - p0).normalized()
			var up := Vector3.UP
			if abs(dir.dot(up)) > 0.99:
				up = Vector3.FORWARD
			root_node.add_child(seg)
			seg.look_at(seg.position + dir, up)
			seg.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))

	# 4 Sagging High-Voltage Cables from Pole Insulators across to Building Roof
	make_cable.call(Vector3(-5.2 - 0.95, 0.15 + 5.38, 6.4), Vector3(-4.2, 5.5, 2.7), 0.65, 0.035)
	make_cable.call(Vector3(-5.2 - 0.50, 0.15 + 5.38, 6.4), Vector3(-3.2, 5.5, 2.7), 0.75, 0.035)
	make_cable.call(Vector3(-5.2 - 0.75, 0.15 + 5.98, 6.4), Vector3(-2.2, 5.5, 2.7), 0.85, 0.035)
	make_cable.call(Vector3(-5.2 + 0.50, 0.15 + 5.38, 6.4), Vector3(0.0, 5.5, 2.7), 0.95, 0.035)

	# 9. Runner Protagonist (Sidewalk checking comms)
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	runner.position = Vector3(-0.8, 0.15, 4.8)
	runner.rotation_degrees = Vector3(0.0, 20.0, 0.0)
	runner.set_physics_process(false)
	runner.set_process(false)
	root_node.add_child(runner)

	# Outline material for bike
	var bike_outline_mat := StandardMaterial3D.new()
	bike_outline_mat.cull_mode = BaseMaterial3D.CULL_FRONT
	bike_outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bike_outline_mat.albedo_color = Color(0.015, 0.015, 0.02, 1.0)
	bike_outline_mat.grow = true
	bike_outline_mat.grow_amount = 0.010

	# 10. Courier Scrambler Bike (Parked on sidewalk)
	var bike_scene := load("res://models/courier_bike.glb") as PackedScene
	var bike := bike_scene.instantiate() as Node3D
	bike.position = Vector3(0.6, 0.15, 4.8)
	bike.rotation_degrees = Vector3(0.0, -85.0, 0.0)
	root_node.add_child(bike)
	_apply_outline(bike, bike_outline_mat)

	# 11. Scrap Worker Bot (On sidewalk near runner in full foreground view)
	var worker_scene := load("res://scenes/entities/scrap_worker.tscn") as PackedScene
	var worker := worker_scene.instantiate() as CharacterBody3D
	worker.position = Vector3(-1.6, 0.15, 4.4)
	worker.rotation_degrees = Vector3(0.0, 15.0, 0.0)
	worker.set_physics_process(false)
	worker.set_process(false)
	root_node.add_child(worker)

	# 12. Utility Crawler Bot (Patrolling near kiosk)
	var crawler_scene := load("res://scenes/entities/utility_crawler.tscn") as PackedScene
	var crawler := crawler_scene.instantiate() as CharacterBody3D
	crawler.position = Vector3(2.0, 0.15, 4.2)
	crawler.rotation_degrees = Vector3(0.0, -25.0, 0.0)
	crawler.set_physics_process(false)
	crawler.set_process(false)
	root_node.add_child(crawler)

	var cam := Camera3D.new()
	root_node.add_child(cam)

	# Wait a few frames for scene setup and shaders
	for _i in range(8):
		await process_frame

	# Ensure actors stayed locked
	runner.position = Vector3(-0.8, 0.15, 4.8)
	worker.position = Vector3(-1.6, 0.15, 4.4)
	crawler.position = Vector3(2.0, 0.15, 4.2)

	# =========================================================================
	# VIEW A: Chinatown Wars 32° Elevated Gameplay View (Panel A Match)
	# =========================================================================
	# DEFECT D FIX: Target lowered from Y=3.8→Y=3.2 (compromise)
	# Shows billboard/rooftop + keeps runner at ~40% frame height.
	# Dist=14.5 + fov=38 widens to fit both floor and crown simultaneously.
	var target_main := Vector3(-0.4, 3.2, 2.6)
	var pitch_rad := deg_to_rad(28.0)
	var yaw_rad := deg_to_rad(-18.0)
	var dist := 14.5
	cam.fov = 38.0

	cam.position = target_main + Vector3(
		sin(yaw_rad) * cos(pitch_rad) * dist,
		sin(pitch_rad) * dist,
		cos(yaw_rad) * cos(pitch_rad) * dist
	)
	cam.look_at(target_main, Vector3.UP)
	cam.make_current()

	for _i in range(15):
		await process_frame

	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/storefront_render_32deg.png")
	print("Saved storefront gameplay 32-deg: ", OUT_DIR + "/storefront_render_32deg.png")

	# =========================================================================
	# VIEW B: Front Elevation (Panel B Match - Architectural Facade View)
	# =========================================================================
	# Hide sidewalk actors for clean architectural facade inspection
	runner.visible = false
	bike.visible = false
	worker.visible = false
	crawler.visible = false

	var target_front := Vector3(-0.2, 5.0, 2.5)
	cam.fov = 38.0
	cam.position = Vector3(-0.2, 5.0, 15.2)
	cam.look_at(target_front, Vector3.UP)

	for _i in range(15):
		await process_frame

	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/storefront_render_front_elev.png")
	print("Saved storefront front elevation: ", OUT_DIR + "/storefront_render_front_elev.png")

	# =========================================================================
	# VIEW C: Right Side Elevation (Panel C Match - Side Wall & Stencils)
	# =========================================================================
	# Keep dumpster_side visible so Panel C shows dumpster under wall stencils per concept art
	kiosk.visible = false
	dumpster.visible = false
	dumpster_side.visible = true
	pole.visible = false
	road_marking.visible = false

	var target_side := Vector3(4.62, 3.8, 0.0)
	cam.fov = 42.0
	cam.position = Vector3(14.5, 4.0, 0.0)
	cam.look_at(target_side, Vector3.UP)

	for _i in range(15):
		await process_frame

	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/storefront_render_side_elev.png")
	print("Saved storefront side elevation: ", OUT_DIR + "/storefront_render_side_elev.png")

	print("Storefront visual captures complete!")
	quit(0)

func _apply_outline(node: Node, outline_mat: Material) -> void:
	if node is MeshInstance3D and node.mesh:
		for s in range(node.mesh.get_surface_count()):
			var active_mat = node.get_active_material(s)
			if active_mat is StandardMaterial3D:
				active_mat.next_pass = outline_mat
	for child in node.get_children():
		_apply_outline(child, outline_mat)
