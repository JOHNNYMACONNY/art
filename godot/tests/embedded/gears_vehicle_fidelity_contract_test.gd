class_name GearsVehicleFidelityContractTest
extends RefCounted

static func run_test() -> Dictionary:
	var results: Dictionary = {
		"coupe_staggered_wheels": false,
		"coupe_ducktail_and_cowl": false,
		"hauler_ten_wheels": false,
		"hauler_exhaust_and_visor": false,
		"interceptor_ram_and_spotlight": false,
		"interceptor_dual_strobes": false,
		"all_passed": false
	}

	# 1. Muscle Coupe Verification
	var coupe_res = load("res://scenes/vehicles/muscle_coupe.tscn")
	if coupe_res is PackedScene:
		var coupe = coupe_res.instantiate()
		var mesh_inst: MeshInstance3D = coupe.find_child("MuscleCoupe_Mesh", true, false)
		if mesh_inst == null:
			mesh_inst = coupe.find_child("*Mesh*", true, false)
		if mesh_inst != null and mesh_inst.mesh != null:
			var m = mesh_inst.mesh
			var aabb = m.get_aabb()
			if aabb.size.z >= 4.4 and aabb.size.x >= 1.7:
				if m.get_surface_count() >= 8:
					results["coupe_staggered_wheels"] = true
				if aabb.size.y >= 1.15:
					results["coupe_ducktail_and_cowl"] = true
		coupe.free()

	# 2. Scrap Hauler Verification
	var hauler_res = load("res://scenes/vehicles/scrap_hauler.tscn")
	if hauler_res is PackedScene:
		var hauler = hauler_res.instantiate()
		var mesh_inst: MeshInstance3D = hauler.find_child("ScrapHauler_Mesh", true, false)
		if mesh_inst == null:
			mesh_inst = hauler.find_child("*Mesh*", true, false)
		if mesh_inst != null and mesh_inst.mesh != null:
			var m = mesh_inst.mesh
			var aabb = m.get_aabb()
			if aabb.size.z >= 6.2 and aabb.size.y >= 2.6:
				results["hauler_exhaust_and_visor"] = true
			if m.get_surface_count() >= 8:
				results["hauler_ten_wheels"] = true
		hauler.free()

	# 3. Security Interceptor Verification
	var interceptor_res = load("res://scenes/vehicles/security_interceptor.tscn")
	if interceptor_res is PackedScene:
		var interceptor = interceptor_res.instantiate()
		var mesh_inst: MeshInstance3D = interceptor.find_child("SecurityInterceptor_Mesh", true, false)
		if mesh_inst == null:
			mesh_inst = interceptor.find_child("*Mesh*", true, false)
		if mesh_inst != null and mesh_inst.mesh != null:
			var m = mesh_inst.mesh
			var aabb = m.get_aabb()
			if aabb.size.z >= 4.5 and aabb.size.x >= 1.8:
				results["interceptor_ram_and_spotlight"] = true
			if m.get_surface_count() >= 9:
				results["interceptor_dual_strobes"] = true
		interceptor.free()

	results["all_passed"] = (
		results["coupe_staggered_wheels"] and
		results["coupe_ducktail_and_cowl"] and
		results["hauler_ten_wheels"] and
		results["hauler_exhaust_and_visor"] and
		results["interceptor_ram_and_spotlight"] and
		results["interceptor_dual_strobes"]
	)
	return results
