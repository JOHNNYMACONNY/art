extends RefCounted

# Muscle Coupe Verification Contract
# Validates production node existence, hierarchy, constants, and mount readiness

static func verify(scene_root: Node) -> String:
	if scene_root == null:
		return "Playable scene root is missing"

	var coupe := scene_root.get_node_or_null("MuscleCoupe") as CharacterBody3D
	if coupe == null:
		return "MuscleCoupe node missing on scene root"

	if not coupe.has_node("CollisionShape3D"):
		return "MuscleCoupe missing CollisionShape3D"

	var col = coupe.get_node("CollisionShape3D") as CollisionShape3D
	if not col.shape is BoxShape3D:
		return "MuscleCoupe CollisionShape3D is not BoxShape3D"

	var sz: Vector3 = col.shape.size
	if sz.x < 1.5 or sz.x > 2.2 or sz.z < 3.5 or sz.z > 5.0:
		return "MuscleCoupe CollisionShape3D size outside bounds: %s" % sz

	if not coupe.has_node("VisualRoot"):
		return "MuscleCoupe missing VisualRoot"

	if not coupe.has_node("RiderSocket"):
		return "MuscleCoupe missing RiderSocket"

	if not coupe.has_node("MountInteractable"):
		return "MuscleCoupe missing MountInteractable"

	var mount_interactable = coupe.get_node("MountInteractable") as InteractableBase
	if mount_interactable == null or not mount_interactable.is_powered:
		return "MuscleCoupe MountInteractable not powered or invalid"

	if not is_equal_approx(coupe.get("max_speed"), 21.0):
		return "MuscleCoupe max_speed expected 21.0, got %.2f" % coupe.get("max_speed")

	if not is_equal_approx(coupe.get("acceleration"), 14.5):
		return "MuscleCoupe acceleration expected 14.5, got %.2f" % coupe.get("acceleration")

	if not is_equal_approx(coupe.get("braking_friction"), 14.0):
		return "MuscleCoupe braking_friction expected 14.0, got %.2f" % coupe.get("braking_friction")

	if not is_equal_approx(coupe.get("steering_speed"), 2.4):
		return "MuscleCoupe steering_speed expected 2.4, got %.2f" % coupe.get("steering_speed")

	if not is_equal_approx(coupe.get("dismount_speed_limit"), 1.5):
		return "MuscleCoupe dismount_speed_limit expected 1.5, got %.2f" % coupe.get("dismount_speed_limit")

	return ""
