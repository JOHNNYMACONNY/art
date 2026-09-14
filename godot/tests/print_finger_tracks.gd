extends SceneTree
func _init():
	var r = load("res://scenes/player/runner.tscn").instantiate()
	var ap = r.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var anim = ap.get_animation("car_drive")
	for i in range(anim.get_track_count()):
		var p = str(anim.track_get_path(i))
		if "Hand" in p or "Index" in p or "Thumb" in p or "Middle" in p or "Ring" in p or "Pinky" in p:
			var val = anim.track_get_key_value(i, 0)
			print(p, " -> ", val)
	quit(0)
