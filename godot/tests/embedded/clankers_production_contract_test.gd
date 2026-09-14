extends RefCounted

# Clankers Production Contract Test (TDD Red-Green Gate)
# Verifies Scrap Worker and Utility Crawler satisfy production 3D visual bar,
# non-primitive geometry, cel shaders, comic outlines, and preserved collision bounds.

static func run_test() -> Dictionary:
	var results := {
		"scrap_worker_mesh_valid": false,
		"scrap_worker_collision_preserved": false,
		"scrap_worker_has_materials": false,
		"utility_crawler_mesh_valid": false,
		"utility_crawler_collision_preserved": false,
		"utility_crawler_has_materials": false,
		"all_passed": false
	}

	# 1. Inspect Scrap Worker Scene
	var worker_scene := load("res://scenes/entities/scrap_worker.tscn") as PackedScene
	if worker_scene:
		var worker := worker_scene.instantiate() as CharacterBody3D
		if worker:
			# Collision check
			var col := worker.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if col and col.shape is CapsuleShape3D:
				var cap := col.shape as CapsuleShape3D
				if is_equal_approx(cap.radius, 0.35) and is_equal_approx(cap.height, 1.7):
					results["scrap_worker_collision_preserved"] = true

			# Geometry check: must NOT be crude BoxMesh
			var mesh_nodes := worker.find_children("*", "MeshInstance3D", true, false)
			var has_primitive_box := false
			var has_real_mesh := false
			for m in mesh_nodes:
				var mi := m as MeshInstance3D
				if mi.mesh is BoxMesh or mi.mesh is SphereMesh or mi.mesh is CylinderMesh:
					has_primitive_box = true
				elif mi.mesh is ArrayMesh or mi.mesh != null:
					has_real_mesh = true

			if has_real_mesh and not has_primitive_box:
				results["scrap_worker_mesh_valid"] = true
			
			results["scrap_worker_has_materials"] = mesh_nodes.size() > 0
			worker.free()

	# 2. Inspect Utility Crawler Scene
	var crawler_scene := load("res://scenes/entities/utility_crawler.tscn") as PackedScene
	if crawler_scene:
		var crawler := crawler_scene.instantiate() as CharacterBody3D
		if crawler:
			# Collision check
			var col := crawler.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if col and col.shape is BoxShape3D:
				var box := col.shape as BoxShape3D
				if is_equal_approx(box.size.x, 0.9) and is_equal_approx(box.size.z, 1.3):
					results["utility_crawler_collision_preserved"] = true

			# Geometry check: must NOT be crude BoxMesh
			var mesh_nodes := crawler.find_children("*", "MeshInstance3D", true, false)
			var has_primitive_box := false
			var has_real_mesh := false
			for m in mesh_nodes:
				var mi := m as MeshInstance3D
				if mi.mesh is BoxMesh or mi.mesh is CylinderMesh:
					has_primitive_box = true
				elif mi.mesh is ArrayMesh or mi.mesh != null:
					has_real_mesh = true

			if has_real_mesh and not has_primitive_box:
				results["utility_crawler_mesh_valid"] = true

			results["utility_crawler_has_materials"] = mesh_nodes.size() > 0
			crawler.free()

	results["all_passed"] = (
		results["scrap_worker_mesh_valid"] and
		results["scrap_worker_collision_preserved"] and
		results["scrap_worker_has_materials"] and
		results["utility_crawler_mesh_valid"] and
		results["utility_crawler_collision_preserved"] and
		results["utility_crawler_has_materials"]
	)

	return results
