extends SceneTree

const Contract = preload("res://tests/security_checkpoint_world_event_contract.gd")

var _scene: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _run() -> void:
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		push_error("Could not load scrap_test_block.tscn")
		await _finish(1)
		return

	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame

	var err := Contract.verify(_scene)
	if err != "":
		push_error("[CHECKPOINT_WORLD_EVENT] FAIL: %s" % err)
		await _finish(1)
		return

	# Post-147 regression: high-speed breach is entered synchronously, but the
	# physics shape must disable safely on the deferred engine turn.
	var event := _scene.get_node_or_null("SecurityCheckpointWorldEvent")
	var checkpoint := _scene.get_node_or_null("GearsDistrictSlice01B/StreetClutter/SecurityCheckpoint") as StaticBody3D
	var player := _scene.get_node_or_null("Runner") as Node3D
	var audio := _scene.get_node_or_null("AudioManager") as AudioManager
	if event == null or checkpoint == null or player == null or audio == null:
		push_error("[CHECKPOINT_WORLD_EVENT] FAIL: async breach dependencies missing")
		await _finish(1)
		return
	var barrier_col := checkpoint.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if barrier_col == null:
		push_error("[CHECKPOINT_WORLD_EVENT] FAIL: checkpoint collision shape missing")
		await _finish(1)
		return

	event.call("reset_world_event")
	player.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.10)
	audio.reset_event_counts()
	_scene.call("_check_checkpoint_ram_breach", 8.5, checkpoint.global_position)
	if event.get("current_state") != 3:
		push_error("[CHECKPOINT_WORLD_EVENT] FAIL: high-speed breach did not enter BREACHED")
		await _finish(1)
		return
	await process_frame
	await physics_frame
	if not barrier_col.disabled:
		push_error("[CHECKPOINT_WORLD_EVENT] FAIL: deferred breach did not disable barrier collision")
		await _finish(1)
		return
	if audio.get_event_count(AudioManager.SoundEvent.COLLISION_HEAD_ON) < 1 or audio.get_event_count(AudioManager.SoundEvent.GATE_SLAM) < 1:
		push_error("[CHECKPOINT_WORLD_EVENT] FAIL: breach audio events were not emitted")
		await _finish(1)
		return

	event.call("reset_world_event")
	if event.get("current_state") != 0 or barrier_col.disabled:
		push_error("[CHECKPOINT_WORLD_EVENT] FAIL: reset did not restore ARMED collider state")
		await _finish(1)
		return

	# A reset issued before the deferred breach write executes must invalidate
	# that stale disable rather than leaving ARMED state non-solid.
	player.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.10)
	if event.get("current_state") != 1:
		push_error("[CHECKPOINT_WORLD_EVENT] FAIL: reset-race fixture did not enter STANDOFF")
		await _finish(1)
		return
	if not bool(event.call("ram_breach", 8.5)):
		push_error("[CHECKPOINT_WORLD_EVENT] FAIL: reset-race breach was rejected")
		await _finish(1)
		return
	event.call("reset_world_event")
	await process_frame
	await physics_frame
	if event.get("current_state") != 0 or barrier_col.disabled:
		push_error("[CHECKPOINT_WORLD_EVENT] FAIL: stale deferred breach disable overrode reset")
		await _finish(1)
		return

	print("[CHECKPOINT_WORLD_EVENT] 100% CONTRACT PASS")
	await _finish(0)
