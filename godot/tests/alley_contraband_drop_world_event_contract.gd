extends RefCounted

const ENTRY_SOCKET_PATH := "GearsDistrictSlice01B/ServiceAlleyEntrySocket"
const STASH_PROP_PATH := "GearsDistrictSlice01B/StreetClutter/CardboardBoxStack"
const EXIT_SOCKET_PATH := "GearsDistrictSlice01B/ServiceAlleyExitSocket"

static func verify(scene_root: Node) -> String:
	if scene_root == null:
		return "Playable scene root is missing"

	var event := scene_root.get_node_or_null("AlleyContrabandDropWorldEvent")
	if event == null or not event.has_method("get_world_event_contract"):
		return "AlleyContrabandDropWorldEvent production node/contract is missing"

	var contract: Dictionary = event.call("get_world_event_contract")
	if contract.get("directive", "") != "contraband_alley_drop":
		return "Contraband alley directive must be contraband_alley_drop"
	if contract.get("actor", "") != "MAYOR_BURN_DROP":
		return "Contraband alley actor identity is incorrect"
	if contract.get("zone", "") != "gears_service_alley":
		return "Contraband alley zone identity is incorrect"
	if int(contract.get("reward_credits", 0)) != 250:
		return "Contraband alley reward must be 250 credits"
	if contract.get("entry_socket_path", "") != ENTRY_SOCKET_PATH:
		return "Contraband alley points at wrong entry socket path"
	if contract.get("stash_prop_path", "") != STASH_PROP_PATH:
		return "Contraband alley points at wrong stash prop path"
	if contract.get("exit_socket_path", "") != EXIT_SOCKET_PATH:
		return "Contraband alley points at wrong exit socket path"

	var entry_socket := scene_root.get_node_or_null(ENTRY_SOCKET_PATH) as Marker3D
	var stash_prop := scene_root.get_node_or_null(STASH_PROP_PATH) as Node3D
	var exit_socket := scene_root.get_node_or_null(EXIT_SOCKET_PATH) as Marker3D
	if entry_socket == null:
		return "Required entry socket missing at: %s" % ENTRY_SOCKET_PATH
	if stash_prop == null:
		return "Required stash prop missing at: %s" % STASH_PROP_PATH
	if exit_socket == null:
		return "Required exit socket missing at: %s" % EXIT_SOCKET_PATH

	var player := scene_root.get_node_or_null("Runner") as Node3D
	var audio := scene_root.get_node_or_null("AudioManager") as AudioManager
	if player == null or audio == null:
		return "Contraband drop world event dependencies missing"

	var lock_id := int(AudioManager.SoundEvent.SIGNAL_LOCK)
	var completion_id := int(AudioManager.SoundEvent.COMPLETION)

	# Reset baseline
	event.set_process(false)
	audio.reset_event_counts()
	audio.set_mix_state(AudioManager.MixState.CALM)
	event.call("reset_world_event")

	if event.get("current_state") != 0: # State.ARMED
		return "Fresh event did not start in ARMED state"

	# TEST 1: Approach entry socket triggers DISCOVERED state
	player.global_position = entry_socket.global_position + Vector3(0.0, 0.0, 2.0)
	event.call("_process", 0.10)
	if event.get("current_state") != 1: # State.DISCOVERED
		return "Approaching entry socket did not transition to DISCOVERED state"

	# TEST 1B: Touch UI prompt during DISCOVERED
	var touch_ui = scene_root.get("touch_ui")
	if touch_ui:
		scene_root.call("_evaluate_target_selection")
		if touch_ui.action_button.text != "[E] SECURE STASH":
			return "Touch UI ActionButton did not display SECURE STASH prompt on foot: got %s" % touch_ui.action_button.text

		touch_ui.current_mode = 1 # VEHICLE_DRIVING
		scene_root.call("_evaluate_target_selection")
		if not touch_ui.route_switch_button.visible or touch_ui.route_switch_button.text != "[F] SECURE STASH":
			return "Touch UI RouteSwitchButton did not display vehicle SECURE STASH prompt: visible=%s, text=%s" % [str(touch_ui.route_switch_button.visible), touch_ui.route_switch_button.text]
		touch_ui.current_mode = 0 # FOOT_TRAVERSAL
		scene_root.call("_evaluate_target_selection")

	# TEST 2: Collecting stash transitions to COLLECTED and plays audio
	audio.reset_event_counts()
	scene_root.call("_on_action_pressed")
	if event.get("current_state") != 2: # State.COLLECTED
		return "Action press did not transition to COLLECTED state"
	if audio.get_event_count(lock_id) < 1:
		return "Stash collection did not emit signal lock confirmation audio"

	# TEST 3: Heading to exit socket and delivering drop
	player.global_position = exit_socket.global_position + Vector3(0.0, 0.0, 1.0)
	event.call("_process", 0.10)
	if touch_ui:
		scene_root.call("_evaluate_target_selection")
		if touch_ui.action_button.text != "[E] DELIVER DROP":
			return "Touch UI did not display DELIVER DROP prompt at exit socket: got %s" % touch_ui.action_button.text

	audio.reset_event_counts()
	scene_root.call("_on_action_pressed")
	if event.get("current_state") != 3: # State.DELIVERED
		return "Action press at exit socket did not transition to DELIVERED state"
	if audio.get_event_count(completion_id) < 1:
		return "Delivery at exit socket did not emit completion audio"

	# TEST 4: Full reset restores ARMED state
	event.call("reset_world_event")
	if event.get("current_state") != 0:
		return "reset_world_event did not restore ARMED state"

	return ""
