extends SceneTree

var _scene: Node = null

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[WANTED_HUD_LAYOUT] %s" % message)
	if is_instance_valid(_scene):
		_scene.queue_free()
	await process_frame
	quit(1)

func _run() -> void:
	var runtime := root.get_node_or_null("BurnsideWantedRuntime")
	if runtime == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return

	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load real ScrapTestBlock")
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	runtime.call("bind_to_scene", _scene)
	await process_frame

	var label := _scene.get_node_or_null("CanvasLayer/WantedStatusLabel") as Label
	if label == null:
		await _fail("WantedStatusLabel is missing")
		return

	# The mission objective panel owns the upper-left information lane. Wanted is
	# persistent high-priority state, so keep it in the opposite upper-right lane.
	if label.anchor_left < 0.99 or label.anchor_right < 0.99:
		await _fail("Wanted HUD is not anchored to the top-right lane")
		return
	if label.offset_right > -12.0 or label.offset_left > -180.0:
		await _fail("Wanted HUD lacks a bounded right-edge margin/width")
		return
	if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_RIGHT:
		await _fail("Wanted HUD text is not right-aligned")
		return

	print("[WANTED_HUD_LAYOUT] PASS")
	_scene.queue_free()
	await process_frame
	quit(0)
