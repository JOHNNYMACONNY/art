class_name PropScrapDumpster
extends StaticBody3D

# Scrap Dumpster Controller
# Enforces two-tone comic cel shader and inverted hull outline across dumpster and scrap parts

@export var material_main: Material

func _ready() -> void:
	_setup_materials()

func _setup_materials() -> void:
	var meshes := find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi := m as MeshInstance3D
		if not mi:
			continue
		var surf_count: int = mi.get_surface_override_material_count()
		if surf_count == 0 and mi.mesh:
			surf_count = mi.mesh.get_surface_count()
		for s in range(surf_count):
			if material_main:
				mi.set_surface_override_material(s, material_main.duplicate())
