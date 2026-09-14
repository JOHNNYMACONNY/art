class_name BurnsideStorefront
extends Node3D

# Burnside Salvage & Repair Storefront Controller
# Enforces two-tone comic cel shader and inverted hull ink outlines across building meshes

@export var material_main: Material
@export var material_neon: Material

func _ready() -> void:
	print("BurnsideStorefront _ready called! material_main: ", material_main, " material_neon: ", material_neon)
	_setup_materials()

func _setup_materials() -> void:
	var meshes := find_children("*", "MeshInstance3D", true, false)
	print("Found meshes: ", meshes.size())
	for m in meshes:
		var mi := m as MeshInstance3D
		if not mi:
			continue
		var surf_count: int = mi.get_surface_override_material_count()
		if surf_count == 0 and mi.mesh:
			surf_count = mi.mesh.get_surface_count()
		print("Mesh ", mi.name, " applying ", surf_count, " surfaces")
		for s in range(surf_count):
			if s == 1 and material_neon:
				mi.set_surface_override_material(s, material_neon.duplicate())
			elif material_main:
				mi.set_surface_override_material(s, material_main.duplicate())
