extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate()
	root.add_child(runner)

	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var lib := ap.get_animation_library("")

	var old_anim := lib.get_animation("bike_ride")
	var new_anim := Animation.new()
	new_anim.length = 5.0

	lib.add_animation("bike_ride", new_anim)
	var cur_anim := lib.get_animation("bike_ride")
	print("cur_anim length: ", cur_anim.length, " (was it replaced? ", cur_anim == new_anim, ")")

	lib.remove_animation("bike_ride")
	lib.add_animation("bike_ride", new_anim)
	var cur_anim2 := lib.get_animation("bike_ride")
	print("after remove+add length: ", cur_anim2.length, " (was it replaced? ", cur_anim2 == new_anim, ")")

	quit(0)
