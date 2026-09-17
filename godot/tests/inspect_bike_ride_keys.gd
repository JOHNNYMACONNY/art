extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate()
	root.add_child(runner)
	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var anim := ap.get_animation("bike_ride")

	print("=== BIKE_RIDE ANIMATION TRACK DETAILS ===")
	for i in range(anim.get_track_count()):
		var path := anim.track_get_path(i)
		var type := anim.track_get_type(i)
		var n_keys := anim.track_get_key_count(i)
		var val0 = anim.track_get_key_value(i, 0) if n_keys > 0 else "none"
		print("Track ", i, " [", type, "] ", path, " keys: ", n_keys, " val[0]=", val0)

	quit(0)
