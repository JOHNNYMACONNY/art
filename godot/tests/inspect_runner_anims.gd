extends SceneTree

func _init():
	var scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = scene.instantiate()
	root.add_child(runner)
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	print("Animations in runner:")
	for anim_name in ap.get_animation_list():
		var anim = ap.get_animation(anim_name)
		print(" - ", anim_name, " len: ", anim.length, " tracks: ", anim.get_track_count())
	quit(0)
