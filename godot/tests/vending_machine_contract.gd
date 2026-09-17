extends RefCounted

## Verification Contract for Commercial Storefront Vending Machine Contraband Hack
## Validates tactical hacking, 3-hit melee tamper breach, vehicle ram breach, and deterministic reset.

const PropVendingMachineScript = preload("res://scripts/props/prop_vending_machine.gd")

static func verify(scene_root: Node) -> String:
	if scene_root == null:
		return "Playable scene root is missing"

	var event := scene_root.get_node_or_null("VendingMachineWorldEvent")
	if event == null or not event.has_method("get_world_event_contract"):
		return "VendingMachineWorldEvent node or get_world_event_contract missing"

	var contract: Dictionary = event.call("get_world_event_contract")
	if contract.get("directive", "") != "vending_machine_contraband_hack":
		return "Directive must be vending_machine_contraband_hack"
	if contract.get("actor", "") != "COMMERCIAL_VENDING_MACHINE":
		return "Actor must be COMMERCIAL_VENDING_MACHINE"
	if contract.get("zone", "") != "commercial_frontage":
		return "Zone must be commercial_frontage"
	if int(contract.get("reward_scrap", 0)) != 80:
		return "Reward scrap must be 80"
	if int(contract.get("breach_scrap", 0)) != 120:
		return "Breach scrap must be 120"
	if int(contract.get("max_durability", 0)) != 3:
		return "Max durability must be 3"
	if absf(float(contract.get("min_ram_speed", 0.0)) - 4.5) > 0.001:
		return "Min ram speed must be 4.5"

	var machine = scene_root.get_node_or_null("PropVendingMachine")
	if machine == null and "vending_machine" in scene_root:
		machine = scene_root.get("vending_machine")
	if machine == null:
		return "PropVendingMachine entity instance missing in playable scene"

	var player: Node3D = scene_root.get_node_or_null("Runner") as Node3D
	var audio: AudioManager = scene_root.get_node_or_null("AudioManager") as AudioManager
	var touch_ui = scene_root.get("touch_ui")

	# =========================================================================
	# STAGE 1: Baseline cold start state
	# =========================================================================
	scene_root.call("reset_slice")
	if machine.current_state != PropVendingMachineScript.VendingState.READY:
		return "Vending machine must start in READY state"
	if machine.current_durability != 3:
		return "Vending machine durability must start at 3"
	if machine.is_hacked or machine.is_looted or machine.is_rammed:
		return "Vending machine must start unhacked, unlooted, and unrammed"
	if not machine.is_in_group("damageable") or not machine.is_in_group("strike_target"):
		return "Vending machine must be in groups damageable and strike_target"
	var interactable = machine.get_node_or_null("VendingMachineInteractable")
	if interactable == null:
		return "VendingMachineInteractable proxy missing on vending machine"

	# =========================================================================
	# STAGE 2: Target presentation & peaceful [E] HACK TERMINAL interaction
	# =========================================================================
	player.global_position = machine.global_position + Vector3(0.0, 0.0, 1.4)
	scene_root.call("_process", 0.016)
	scene_root.call("_evaluate_target_selection")

	if touch_ui and touch_ui.action_button:
		if touch_ui.action_button.text != "[E] HACK TERMINAL":
			return "Touch UI ActionButton did not display [E] HACK TERMINAL, got: %s" % touch_ui.action_button.text

	var start_completion_count := audio.get_event_count(int(AudioManager.SoundEvent.COMPLETION)) if audio else 0
	scene_root.call("_on_action_pressed")

	if machine.current_state != PropVendingMachineScript.VendingState.HACKED:
		return "Interacting with vending machine must transition it to HACKED state"
	if not machine.is_hacked:
		return "Interacting with vending machine must set is_hacked = true"
	if machine.screen_light and machine.screen_light.light_color.g < 0.9:
		return "Hacked vending machine screen light must transition to green"
	if audio and audio.get_event_count(int(AudioManager.SoundEvent.COMPLETION)) <= start_completion_count:
		return "Hacking vending machine must emit COMPLETION audio event"

	# Re-evaluating target after hacked
	scene_root.call("_evaluate_target_selection")
	if touch_ui and touch_ui.action_button:
		if touch_ui.action_button.text == "[E] HACK TERMINAL":
			return "Hacked vending machine must not continue offering [E] HACK TERMINAL"

	# =========================================================================
	# STAGE 3: Melee combat 3-hit breach & scrap spill
	# =========================================================================
	scene_root.call("reset_slice")
	if machine.current_state != PropVendingMachineScript.VendingState.READY:
		return "Reset must restore READY state before melee test"
	if machine.current_durability != 3:
		return "Reset must restore durability to 3"

	# Strike 1
	machine.take_hit(1, machine.global_position, Vector3.FORWARD)
	if machine.current_durability != 2:
		return "Strike 1 must reduce vending machine durability from 3 to 2"
	if machine.current_state != PropVendingMachineScript.VendingState.READY:
		return "Strike 1 must not breach vending machine"

	# Strike 2
	machine.take_hit(1, machine.global_position, Vector3.FORWARD)
	if machine.current_durability != 1:
		return "Strike 2 must reduce vending machine durability from 2 to 1"
	if machine.current_state != PropVendingMachineScript.VendingState.READY:
		return "Strike 2 must not breach vending machine"

	# Strike 3 (lethal breach)
	var start_siren_count := audio.get_event_count(int(AudioManager.SoundEvent.SIREN_ALARM)) if audio else 0
	machine.take_hit(1, machine.global_position, Vector3.FORWARD)
	if machine.current_durability != 0:
		return "Strike 3 must reduce vending machine durability to 0"
	if machine.current_state != PropVendingMachineScript.VendingState.BREACHED:
		return "Strike 3 must transition vending machine to BREACHED state"
	if not machine.is_looted:
		return "Strike 3 lethal breach must set is_looted = true"
	if machine.debris_instances.is_empty():
		return "Lethal strike must scatter debris shards"
	if audio and audio.get_event_count(int(AudioManager.SoundEvent.SIREN_ALARM)) <= start_siren_count:
		return "Breaching vending machine must trigger SIREN_ALARM sound event"

	# =========================================================================
	# STAGE 4: High-speed vehicle ram breach
	# =========================================================================
	scene_root.call("reset_slice")
	if machine.current_state != PropVendingMachineScript.VendingState.READY:
		return "Reset must restore READY state before ram test"

	# Low-speed nudge below 4.5 m/s
	machine.apply_vehicle_ram(3.0, Vector3.FORWARD)
	if machine.current_state != PropVendingMachineScript.VendingState.READY:
		return "Low speed impact (< 4.5 m/s) must not breach vending machine"

	# High-speed impact at >= 4.5 m/s
	var pre_ram_siren := audio.get_event_count(int(AudioManager.SoundEvent.SIREN_ALARM)) if audio else 0
	machine.apply_vehicle_ram(7.5, Vector3.FORWARD)
	if machine.current_state != PropVendingMachineScript.VendingState.BREACHED:
		return "High-speed vehicle ram (>= 4.5 m/s) must transition vending machine to BREACHED state"
	if not machine.is_rammed:
		return "High-speed ram must set is_rammed = true"
	if machine.debris_instances.size() < 4:
		return "High-speed ram must scatter at least 4 debris shards"
	if audio and audio.get_event_count(int(AudioManager.SoundEvent.SIREN_ALARM)) <= pre_ram_siren:
		return "Vehicle ram breach must trigger SIREN_ALARM audio event"

	# =========================================================================
	# STAGE 5: Deterministic reset restores clean cold start state
	# =========================================================================
	scene_root.call("reset_slice")
	if machine.current_state != PropVendingMachineScript.VendingState.READY:
		return "Reset must restore READY state after ram destruction"
	if machine.current_durability != 3:
		return "Reset must restore durability to 3"
	if machine.is_rammed or machine.is_looted or machine.is_hacked:
		return "Reset must clear rammed, looted, and hacked flags"
	if not machine.debris_instances.is_empty():
		return "Reset must clear and free all debris shards"
	if machine.screen_light and machine.screen_light.light_energy < 1.0:
		return "Reset must restore screen light energy"

	return ""
