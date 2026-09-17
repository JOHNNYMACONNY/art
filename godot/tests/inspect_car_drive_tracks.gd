extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	root.add_child(runner)
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var anim = ap.get_animation("car_drive")
	var tracks = [0, 1, 49, 50]
	for t in tracks:
		print("Track ", t, " (", anim.track_get_path(t), "): val = ", anim.track_get_key_value(t, 0))
	quit(0)
