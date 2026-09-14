extends RefCounted

const CHECKPOINT_PROP_PATH := "GearsDistrictSlice01B/StreetClutter/SecurityCheckpoint"
const TOON_SHADER_PATH := "res://materials/gears_toon.gdshader"

static func verify(scene_root: Node) -> String:
	if scene_root == null:
		return "Playable scene root is missing"

	var event := scene_root.get_node_or_null("SecurityCheckpointWorldEvent")
	if event == null or not event.has_method("get_world_event_contract"):
		return "SecurityCheckpointWorldEvent production node/contract is missing"

	var contract: Dictionary = event.call("get_world_event_contract")
	if contract.get("directive", "") != "checkpoint_toll_standoff":
		return "Checkpoint world-event directive must be checkpoint_toll_standoff"
	if contract.get("actor", "") != "CIVIC_SECURITY_BARRIER":
		return "Checkpoint world-event actor identity is missing"
	if contract.get("zone", "") != "gears_north_checkpoint":
		return "Checkpoint world-event zone identity is incorrect"
	if int(contract.get("toll_amount", 0)) != 150:
		return "Checkpoint toll amount must be 150 credits"
	if absf(float(contract.get("trigger_radius_m", 0.0)) - 6.5) > 0.001:
		return "Checkpoint trigger radius must be 6.5m"
	if absf(float(contract.get("rearm_radius_m", 0.0)) - 10.0) > 0.001:
		return "Checkpoint rearm radius must be 10.0m"
	if absf(float(contract.get("cooldown_sec", 0.0)) - 8.0) > 0.001:
		return "Checkpoint cooldown must be 8.0s"
	if contract.get("checkpoint_prop_path", "") != CHECKPOINT_PROP_PATH:
		return "Checkpoint contract points at the wrong production prop path"

	var checkpoint := scene_root.get_node_or_null(CHECKPOINT_PROP_PATH) as StaticBody3D
	if checkpoint == null:
		return "Required SecurityCheckpoint prop missing at: %s" % CHECKPOINT_PROP_PATH

	var player := scene_root.get_node_or_null("Runner") as Node3D
	var audio := scene_root.get_node_or_null("AudioManager") as AudioManager
	if player == null or audio == null:
		return "Checkpoint world event runtime dependencies are missing"

	var siren_id := int(AudioManager.SoundEvent.SIREN_ALARM)
	var collision_id := int(AudioManager.SoundEvent.COLLISION_HEAD_ON)
	var gate_slam_id := int(AudioManager.SoundEvent.GATE_SLAM)
	var completion_id := int(AudioManager.SoundEvent.COMPLETION)

	# Reset to clean baseline
	event.set_process(false)
	audio.reset_event_counts()
	audio.set_mix_state(AudioManager.MixState.CALM)
	event.call("reset_world_event")

	if event.get("current_state") != 0: # State.ARMED
		return "Fresh event did not start in ARMED state"
	if not checkpoint.has_node("CollisionShape3D") or checkpoint.get_node("CollisionShape3D").disabled:
		return "Barrier collision shape must be enabled in ARMED state"

	# TEST 1: Approach triggers STANDOFF state & warning audio
	player.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 15.0)
	event.call("_process", 0.10)
	if event.get("current_state") != 0:
		return "Far approach incorrectly altered ARMED state"

	player.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.10)
	if event.get("current_state") != 1: # State.STANDOFF
		return "Proximity entry did not trigger STANDOFF state"
	if audio.get_event_count(siren_id) < 1:
		return "Standoff did not emit security warning audio"

	# TEST 2: Peaceful resolution via Pay Toll
	audio.reset_event_counts()
	var pay_ok: bool = bool(event.call("pay_toll"))
	if not pay_ok:
		return "pay_toll rejected during STANDOFF"
	if event.get("current_state") != 2: # State.TOLL_PAID
		return "pay_toll did not transition to TOLL_PAID state"
	if audio.get_event_count(completion_id) < 1:
		return "pay_toll did not play completion audio confirmation"
	var barrier_col := checkpoint.get_node("CollisionShape3D") as CollisionShape3D
	if not barrier_col.disabled:
		return "Barrier collision must be disabled when toll is paid"

	# TEST 3: Full reset restores ARMED state and barrier collision
	event.call("reset_world_event")
	if event.get("current_state") != 0:
		return "reset_world_event did not restore ARMED state"
	if barrier_col.disabled:
		return "reset_world_event did not re-enable barrier collision"

	# TEST 4: Ramming / Breach resolution at high speed triggers disturbance
	player.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.10)
	if event.get("current_state") != 1:
		return "Re-entry did not enter STANDOFF state"

	# Low speed ram fails
	var low_ram: bool = bool(event.call("ram_breach", 3.0))
	if low_ram:
		return "Low speed ram should not breach checkpoint"

	# High speed ram succeeds and alerts pursuer
	audio.reset_event_counts()
	var high_ram: bool = bool(event.call("ram_breach", 8.5))
	if not high_ram:
		return "High speed ram failed to breach checkpoint"
	if event.get("current_state") != 3: # State.BREACHED
		return "High speed ram did not enter BREACHED state"
	if not barrier_col.disabled:
		return "Barrier collision must be disabled after breach"
	if audio.get_event_count(collision_id) < 1 or audio.get_event_count(gate_slam_id) < 1:
		return "Breach did not play collision and gate slam SFX"

	# Clean reset check
	event.call("reset_world_event")
	if event.get("current_state") != 0 or barrier_col.disabled:
		return "Final reset failed to restore ARMED state"

	return ""
