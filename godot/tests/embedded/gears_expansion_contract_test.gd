class_name GearsExpansionContractTest
extends RefCounted

static func run_test() -> Dictionary:
	var results: Dictionary = {
		"traffic_barrier_valid": false,
		"street_vendor_valid": false,
		"security_checkpoint_valid": false,
		"muscle_coupe_valid": false,
		"scrap_hauler_upgraded": false,
		"security_interceptor_valid": false,
		"district_integration_valid": false,
		"all_passed": false
	}

	# 1. Traffic Barrier Contract
	var barrier_res = load("res://scenes/props/prop_traffic_barrier.tscn")
	if barrier_res is PackedScene:
		var barrier = barrier_res.instantiate()
		var col: CollisionShape3D = barrier.find_child("CollisionShape3D", true, false)
		if col and col.shape is BoxShape3D:
			var sz: Vector3 = col.shape.size
			if sz.x >= 1.6 and sz.x <= 2.6 and sz.y >= 0.6 and sz.y <= 1.4:
				var mesh_inst: MeshInstance3D = barrier.find_child("*Mesh*", true, false)
				if mesh_inst != null:
					results["traffic_barrier_valid"] = true
		barrier.free()

	# 2. Street Vendor Contract
	var vendor_res = load("res://scenes/props/prop_street_vendor.tscn")
	if vendor_res is PackedScene:
		var vendor = vendor_res.instantiate()
		var col: CollisionShape3D = vendor.find_child("CollisionShape3D", true, false)
		if col and col.shape is BoxShape3D:
			var sz: Vector3 = col.shape.size
			if sz.x >= 1.6 and sz.x <= 3.0 and sz.y >= 1.6 and sz.y <= 3.2:
				var mesh_inst: MeshInstance3D = vendor.find_child("*Mesh*", true, false)
				if mesh_inst != null:
					results["street_vendor_valid"] = true
		vendor.free()

	# 3. Security Checkpoint Contract
	var checkpoint_res = load("res://scenes/props/prop_security_checkpoint.tscn")
	if checkpoint_res is PackedScene:
		var checkpoint = checkpoint_res.instantiate()
		var col: CollisionShape3D = checkpoint.find_child("CollisionShape3D", true, false)
		if col and col.shape is BoxShape3D:
			var sz: Vector3 = col.shape.size
			if sz.x >= 1.8 and sz.x <= 5.0 and sz.y >= 1.8 and sz.y <= 4.0:
				var mesh_inst: MeshInstance3D = checkpoint.find_child("*Mesh*", true, false)
				if mesh_inst != null:
					results["security_checkpoint_valid"] = true
		checkpoint.free()

	# 4. Muscle Coupe Contract
	var coupe_res = load("res://scenes/vehicles/muscle_coupe.tscn")
	if coupe_res is PackedScene:
		var coupe = coupe_res.instantiate()
		var col: CollisionShape3D = coupe.find_child("CollisionShape3D", true, false)
		if col and col.shape is BoxShape3D:
			var sz: Vector3 = col.shape.size
			if sz.x >= 1.5 and sz.x <= 2.2 and sz.z >= 3.5 and sz.z <= 5.0:
				var mesh_inst: MeshInstance3D = coupe.find_child("*Mesh*", true, false)
				if mesh_inst != null:
					results["muscle_coupe_valid"] = true
		coupe.free()

	# 5. Scrap Hauler Upgraded Contract
	var hauler_res = load("res://scenes/vehicles/scrap_hauler.tscn")
	if hauler_res is PackedScene:
		var hauler = hauler_res.instantiate()
		var visual_root: Node3D = hauler.find_child("VisualRoot", true, false)
		if visual_root != null:
			# Check for upgraded textured mesh
			var custom_body = visual_root.find_child("HaulerBodyCustom", true, false)
			if custom_body != null and (custom_body is MeshInstance3D or custom_body.find_child("*Mesh*", true, false) != null):
				results["scrap_hauler_upgraded"] = true
		hauler.free()

	# 6. Security Interceptor Contract
	var interceptor_res = load("res://scenes/vehicles/security_interceptor.tscn")
	if interceptor_res is PackedScene:
		var interceptor = interceptor_res.instantiate()
		var col: CollisionShape3D = interceptor.find_child("CollisionShape3D", true, false)
		if col and col.shape is BoxShape3D:
			var sz: Vector3 = col.shape.size
			if sz.x >= 1.5 and sz.x <= 2.2 and sz.z >= 3.4 and sz.z <= 4.8:
				var siren: Node3D = interceptor.find_child("*Siren*", true, false)
				if siren != null:
					results["security_interceptor_valid"] = true
		interceptor.free()

	# 7. District Integration Contract
	var slice_res = load("res://scenes/world/gears_district_slice_01b.tscn")
	if slice_res is PackedScene:
		var slice = slice_res.instantiate()
		var barrier_node = slice.find_child("*Barrier*", true, false)
		var vendor_node = slice.find_child("*Vendor*", true, false)
		var checkpoint_node = slice.find_child("*Checkpoint*", true, false)
		if barrier_node != null and vendor_node != null and checkpoint_node != null:
			results["district_integration_valid"] = true
		slice.free()

	results["all_passed"] = (
		results["traffic_barrier_valid"] and
		results["street_vendor_valid"] and
		results["security_checkpoint_valid"] and
		results["muscle_coupe_valid"] and
		results["scrap_hauler_upgraded"] and
		results["security_interceptor_valid"] and
		results["district_integration_valid"]
	)
	return results
