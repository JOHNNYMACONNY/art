@tool
extends EditorPlugin

var _export_plugin: EditorExportPlugin = null

func _enter_tree() -> void:
	_export_plugin = preload("res://addons/verification_export/verification_exporter.gd").new()
	add_export_plugin(_export_plugin)

func _exit_tree() -> void:
	if _export_plugin != null:
		remove_export_plugin(_export_plugin)
	_export_plugin = null
