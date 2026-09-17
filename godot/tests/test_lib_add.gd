extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate()
	root.add_child(runner)

	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var lib := ap.get_animation_library("")

	print("Initial anims in lib: ", lib.get_animation_list())
	var test_anim := Animation.new()
	var err := lib.add_animation("bike_ride", test_anim)
	print("Result of adding existing 'bike_ride': ", err)

	quit(0)
