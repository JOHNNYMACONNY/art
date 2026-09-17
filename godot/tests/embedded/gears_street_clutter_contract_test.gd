extends RefCounted

## Test contract for Gears District street clutter and visual density (Option A).
## Verifies Slice 1: Streetlamp spot-light pools and pole meshes.
## Verifies Slice 2: Sidewalk cardboard salvage box stacks and newspaper bins.
## Verifies Slice 3: Commercial storefront neon signs and window frames.
## Verifies Slice 4: Overhead utility power wire lines between buildings.

static func verify_slice_1_streetlamps(district: Node3D) -> String:
	if district == null:
		return "GearsDistrictSlice01B node is null"
	
	var clutter := district.get_node_or_null("StreetClutter")
	if clutter == null:
		return "StreetClutter container missing from GearsDistrictSlice01B"
	
	var streetlamp := clutter.get_node_or_null("Streetlamp")
	if streetlamp == null:
		return "Streetlamp node missing from StreetClutter"
	
	var pole := streetlamp.get_node_or_null("PoleMesh") as MeshInstance3D
	if pole == null or pole.mesh == null:
		return "Streetlamp PoleMesh missing or has no mesh"
	if not pole.visible:
		return "Streetlamp PoleMesh must be visible"
		
	var head := streetlamp.get_node_or_null("LampHead") as MeshInstance3D
	if head == null or head.mesh == null:
		return "Streetlamp LampHead missing or has no mesh"
	if not head.visible:
		return "Streetlamp LampHead must be visible"
		
	var pool := streetlamp.get_node_or_null("LightPool") as MeshInstance3D
	if pool == null or pool.mesh == null:
		return "Streetlamp LightPool ground mesh missing or has no mesh"
	if not pool.visible:
		return "Streetlamp LightPool must be visible"
	
	if pool.global_position.y > 0.5 or pool.global_position.y < -0.5:
		return "Streetlamp LightPool must be positioned at ground level"
		
	if pool.scale.x < 2.0 or pool.scale.z < 2.0:
		return "Streetlamp LightPool footprint too small for 3/4 readability"
		
	return ""

static func verify_slice_2_sidewalk_clutter(district: Node3D) -> String:
	if district == null:
		return "GearsDistrictSlice01B node is null"
	
	var clutter := district.get_node_or_null("StreetClutter")
	if clutter == null:
		return "StreetClutter container missing from GearsDistrictSlice01B"
	
	# Newspaper Bins
	var bins := clutter.get_node_or_null("NewspaperBins")
	if bins == null:
		return "NewspaperBins container missing from StreetClutter"
	var blue_bin := bins.get_node_or_null("BlueBin") as MeshInstance3D
	if blue_bin == null or blue_bin.mesh == null:
		return "BlueBin missing or has no mesh"
	var amber_bin := bins.get_node_or_null("AmberBin") as MeshInstance3D
	if amber_bin == null or amber_bin.mesh == null:
		return "AmberBin missing or has no mesh"
		
	# Cardboard Salvage Box Stacks
	var box_stack := clutter.get_node_or_null("CardboardBoxStack")
	if box_stack == null:
		return "CardboardBoxStack container missing from StreetClutter"
	var box1 := box_stack.get_node_or_null("BoxBase") as MeshInstance3D
	if box1 == null or box1.mesh == null:
		return "BoxBase missing or has no mesh in CardboardBoxStack"
	var box2 := box_stack.get_node_or_null("BoxTop") as MeshInstance3D
	if box2 == null or box2.mesh == null:
		return "BoxTop missing or has no mesh in CardboardBoxStack"
		
	# Storm Drain Grate
	var grate := clutter.get_node_or_null("StormDrainGrate") as MeshInstance3D
	if grate == null or grate.mesh == null:
		return "StormDrainGrate missing or has no mesh"
	if not grate.visible:
		return "StormDrainGrate must be visible"
		
	return ""

static func verify_slice_3_storefront(district: Node3D) -> String:
	if district == null:
		return "GearsDistrictSlice01B node is null"
	
	var clutter := district.get_node_or_null("StreetClutter")
	if clutter == null:
		return "StreetClutter container missing from GearsDistrictSlice01B"
	
	var storefront := clutter.get_node_or_null("StorefrontFrames")
	if storefront == null:
		return "StorefrontFrames container missing from StreetClutter"
	
	var window_frame := storefront.get_node_or_null("WindowFrame1") as MeshInstance3D
	if window_frame == null or window_frame.mesh == null:
		return "WindowFrame1 missing or has no mesh"
		
	var neon_sign := storefront.get_node_or_null("NeonSignTrim") as MeshInstance3D
	if neon_sign == null or neon_sign.mesh == null:
		return "NeonSignTrim missing or has no mesh"
		
	var mat := neon_sign.material_override as ShaderMaterial
	if mat == null:
		return "NeonSignTrim must have ShaderMaterial"
	var emission_energy: float = mat.get_shader_parameter("emission_energy")
	if emission_energy < 1.0:
		return "NeonSignTrim must have active glow emission energy >= 1.0"
		
	return ""

static func verify_slice_4_overhead_wires(district: Node3D) -> String:
	if district == null:
		return "GearsDistrictSlice01B node is null"
	
	var clutter := district.get_node_or_null("StreetClutter")
	if clutter == null:
		return "StreetClutter container missing from GearsDistrictSlice01B"
	
	var wires := clutter.get_node_or_null("OverheadWires")
	if wires == null:
		return "OverheadWires container missing from StreetClutter"
	
	var wire1 := wires.get_node_or_null("WireSpan1") as MeshInstance3D
	if wire1 == null or wire1.mesh == null:
		return "WireSpan1 missing or has no mesh"
		
	var wire2 := wires.get_node_or_null("WireSpan2") as MeshInstance3D
	if wire2 == null or wire2.mesh == null:
		return "WireSpan2 missing or has no mesh"
		
	# Wires must be overhead (Y > 3.0m)
	if wire1.global_position.y < 3.0:
		return "OverheadWires must be placed overhead above street level (Y >= 3.0m)"
		
	return ""

static func run(controller: Node) -> void:
	print("[GEARS_CLUTTER_CONTRACT] Running Slices 1-4 tests...")
	var district := controller.get_node_or_null("GearsDistrictSlice01B") as Node3D
	var err1 := verify_slice_1_streetlamps(district)
	assert(err1 == "", "FAIL S1: " + err1)
	var err2 := verify_slice_2_sidewalk_clutter(district)
	assert(err2 == "", "FAIL S2: " + err2)
	var err3 := verify_slice_3_storefront(district)
	assert(err3 == "", "FAIL S3: " + err3)
	var err4 := verify_slice_4_overhead_wires(district)
	assert(err4 == "", "FAIL S4: " + err4)
	print("[GEARS_CLUTTER_CONTRACT] Slices 1-4 PASS!")
