class_name StreetCombatContract
extends RefCounted

# Verification Contract: Street Combat & Physical Tool Improvisation
# Enforces interface invariants, durability parameters, reward values, and signal schemas.

const EXPECTED_LOCKBOX_MAX_DURABILITY: int = 3
const EXPECTED_LOCKBOX_REWARD_CREDITS: int = 150
const EXPECTED_STRIKE_COOLDOWN: float = 0.38
const EXPECTED_STRIKE_REACH: float = 2.2
const EXPECTED_STRIKE_DAMAGE: int = 1

static func verify(scene_root: Node) -> Dictionary:
	var result := {
		"ok": true,
		"errors": []
	}

	if not scene_root:
		result["ok"] = false
		result["errors"].append("Scene root is null")
		return result

	var player = scene_root.get("player")
	if not player:
		result["ok"] = false
		result["errors"].append("Player node missing on scene")
		return result

	# Verify player strike interface
	if not player.has_method("strike"):
		result["ok"] = false
		result["errors"].append("Player missing 'strike()' method")
	if not player.has_signal("strike_triggered"):
		result["ok"] = false
		result["errors"].append("Player missing 'strike_triggered' signal")
	if not player.has_signal("strike_performed"):
		result["ok"] = false
		result["errors"].append("Player missing 'strike_performed' signal")

	# Verify Salvage Lockbox
	var lockbox = scene_root.get("salvage_lockbox")
	if not lockbox:
		lockbox = scene_root.find_child("PropSalvageLockbox", true, false)
	if not lockbox:
		result["ok"] = false
		result["errors"].append("PropSalvageLockbox node missing in scene")
		return result

	if not lockbox.is_in_group("damageable"):
		result["ok"] = false
		result["errors"].append("SalvageLockbox not in 'damageable' group")
	if not lockbox.is_in_group("strike_target"):
		result["ok"] = false
		result["errors"].append("SalvageLockbox not in 'strike_target' group")

	if not lockbox.has_method("take_hit"):
		result["ok"] = false
		result["errors"].append("SalvageLockbox missing 'take_hit()' method")
	if not lockbox.has_method("reset_lockbox"):
		result["ok"] = false
		result["errors"].append("SalvageLockbox missing 'reset_lockbox()' method")
	if not lockbox.has_signal("hit_received"):
		result["ok"] = false
		result["errors"].append("SalvageLockbox missing 'hit_received' signal")
	if not lockbox.has_signal("lockbox_breached"):
		result["ok"] = false
		result["errors"].append("SalvageLockbox missing 'lockbox_breached' signal")
	if not lockbox.has_signal("alarm_triggered"):
		result["ok"] = false
		result["errors"].append("SalvageLockbox missing 'alarm_triggered' signal")

	var max_dur = lockbox.get("MAX_DURABILITY")
	if max_dur != null and int(max_dur) != EXPECTED_LOCKBOX_MAX_DURABILITY:
		result["ok"] = false
		result["errors"].append("SalvageLockbox MAX_DURABILITY expected %d, got %s" % [EXPECTED_LOCKBOX_MAX_DURABILITY, str(max_dur)])

	var reward = lockbox.get("REWARD_CREDITS")
	if reward != null and int(reward) != EXPECTED_LOCKBOX_REWARD_CREDITS:
		result["ok"] = false
		result["errors"].append("SalvageLockbox REWARD_CREDITS expected %d, got %s" % [EXPECTED_LOCKBOX_REWARD_CREDITS, str(reward)])

	return result
