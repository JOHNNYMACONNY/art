extends RefCounted

## Verification Contract for World Event 04 — Municipal Utility Crawler Patrol
## Validates tactical interception, 2-hit melee combat, vehicle ram wreck, and deterministic reset.

const UtilityCrawlerScript = preload("res://scripts/entities/utility_crawler.gd")

static func verify(scene_root: Node) -> String:
	if scene_root == null:
		return "Playable scene root is missing"

	var event := scene_root.get_node_or_null("UtilityCrawlerWorldEvent")
	if event == null or not event.has_method("get_world_event_contract"):
		return "UtilityCrawlerWorldEvent node or get_world_event_contract missing"

	var contract: Dictionary = event.call("get_world_event_contract")
	if contract.get("directive", "") != "municipal_crawler_patrol":
		return "Directive must be municipal_crawler_patrol"
	if contract.get("actor", "") != "MUNICIPAL_UTILITY_CRAWLER":
		return "Actor must be MUNICIPAL_UTILITY_CRAWLER"
	if contract.get("zone", "") != "gears_salvage_circuit":
		return "Zone must be gears_salvage_circuit"
	if int(contract.get("reward_scrap", 0)) != 60:
		return "Reward scrap must be 60"
	if int(contract.get("max_durability", 0)) != 2:
		return "Max durability must be 2"
	if absf(float(contract.get("min_ram_speed", 0.0)) - 4.5) > 0.001:
		return "Min ram speed must be 4.5"

	var crawler: UtilityCrawler = scene_root.get_node_or_null("UtilityCrawler") as UtilityCrawler
	if crawler == null and "utility_crawler" in scene_root:
		crawler = scene_root.get("utility_crawler") as UtilityCrawler
	if crawler == null:
		return "UtilityCrawler entity instance missing in playable scene"

	var player: Node3D = scene_root.get_node_or_null("Runner") as Node3D
	var audio: AudioManager = scene_root.get_node_or_null("AudioManager") as AudioManager
	var touch_ui = scene_root.get("touch_ui")

	# =========================================================================
	# STAGE 1: Baseline cold start state
	# =========================================================================
	scene_root.call("reset_slice")
	if crawler.current_state != UtilityCrawlerScript.CrawlerState.AMBIENT:
		return "Crawler must start in AMBIENT state"
	if crawler.current_durability != 2:
		return "Crawler durability must start at 2"
	if crawler.is_harvested or crawler.is_rammed:
		return "Crawler must start unharvested and unrammed"
	if not crawler.is_in_group("damageable") or not crawler.is_in_group("strike_target"):
		return "Crawler must be in groups damageable and strike_target"
	var interactable := crawler.get_node_or_null("UtilityCrawlerInteractable")
	if interactable == null:
		return "UtilityCrawlerInteractable proxy missing on crawler"

	# =========================================================================
	# STAGE 2: Target presentation & peaceful [E] INTERCEPT interaction
	# =========================================================================
	player.global_position = crawler.global_position + Vector3(0.0, 0.0, 1.2)
	scene_root.call("_process", 0.016)
	scene_root.call("_evaluate_target_selection")

	if touch_ui and touch_ui.action_button:
		if touch_ui.action_button.text != "[E] INTERCEPT":
			return "Touch UI ActionButton did not display [E] INTERCEPT, got: %s" % touch_ui.action_button.text

	var start_completion_count := audio.get_event_count(int(AudioManager.SoundEvent.COMPLETION)) if audio else 0
	scene_root.call("_on_action_pressed")

	if crawler.current_state != UtilityCrawlerScript.CrawlerState.DISABLED:
		return "Interacting with crawler must transition it to DISABLED state"
	if not crawler.is_harvested:
		return "Interacting with crawler must set is_harvested = true"
	if crawler.reward_granted != 60:
		return "Interacting with crawler must grant 60 scrap reward, got: %d" % crawler.reward_granted
	if crawler.beacon_light and crawler.beacon_light.light_energy != 0.0:
		return "Disabled crawler beacon light energy must be 0"
	if audio and audio.get_event_count(int(AudioManager.SoundEvent.COMPLETION)) <= start_completion_count:
		return "Harvesting crawler must emit COMPLETION audio event"

	# Re-evaluating target after harvested
	scene_root.call("_evaluate_target_selection")
	if touch_ui and touch_ui.action_button:
		if touch_ui.action_button.text == "[E] INTERCEPT":
			return "Harvested crawler must not continue offering [E] INTERCEPT"

	# =========================================================================
	# STAGE 3: Melee combat 2-hit disable & scrap spill
	# =========================================================================
	scene_root.call("reset_slice")
	if crawler.current_state != UtilityCrawlerScript.CrawlerState.AMBIENT:
		return "Reset must restore AMBIENT state before melee test"
	if crawler.current_durability != 2:
		return "Reset must restore durability to 2"

	# Strike 1
	crawler.take_hit(1, crawler.global_position, Vector3.FORWARD)
	if crawler.current_durability != 1:
		return "Strike 1 must reduce crawler durability from 2 to 1"
	if crawler.is_harvested:
		return "Strike 1 must not harvest scrap yet"

	# Strike 2 (lethal)
	crawler.take_hit(1, crawler.global_position, Vector3.FORWARD)
	if crawler.current_durability != 0:
		return "Strike 2 must reduce crawler durability to 0"
	if crawler.current_state != UtilityCrawlerScript.CrawlerState.DISABLED:
		return "Lethal melee strike must transition crawler to DISABLED"
	if not crawler.is_harvested or crawler.reward_granted != 60:
		return "Disabling crawler via melee must spill 60 scrap"
	if crawler.debris_instances.is_empty():
		return "Disabling crawler via melee must scatter scrap debris shards"

	# =========================================================================
	# STAGE 4: Vehicle ram combat (low speed vs high speed)
	# =========================================================================
	scene_root.call("reset_slice")
	if crawler.current_state != UtilityCrawlerScript.CrawlerState.AMBIENT:
		return "Reset must restore AMBIENT state before ram test"

	# Sub-threshold nudge (< 4.5 m/s)
	var low_ram_result := crawler.apply_vehicle_ram(3.0, Vector3.FORWARD)
	if low_ram_result:
		return "Sub-threshold ram (< 4.5 m/s) must return false"
	if crawler.is_rammed or crawler.current_state == UtilityCrawlerScript.CrawlerState.WRECKED:
		return "Sub-threshold ram must not wreck crawler"

	# High-speed ram breach (>= 4.5 m/s)
	var high_ram_result := crawler.apply_vehicle_ram(6.5, Vector3.FORWARD)
	if not high_ram_result:
		return "High-speed ram (>= 4.5 m/s) must return true"
	if not crawler.is_rammed:
		return "High-speed ram must set is_rammed = true"
	if crawler.current_state != UtilityCrawlerScript.CrawlerState.WRECKED:
		return "High-speed ram must transition crawler to WRECKED state"
	if crawler.debris_instances.size() < 4:
		return "High-speed ram must scatter at least 4 debris shards, got: %d" % crawler.debris_instances.size()
	if not crawler.is_harvested or crawler.reward_granted != 60:
		return "Wrecking crawler must grant 60 scrap"
	if audio and audio.get_event_count(int(AudioManager.SoundEvent.COLLISION_HEAD_ON)) < 1:
		return "High-speed ram must emit COLLISION_HEAD_ON audio"

	# =========================================================================
	# STAGE 5: Authoritative scene reset
	# =========================================================================
	scene_root.call("reset_slice")
	if crawler.current_state != UtilityCrawlerScript.CrawlerState.AMBIENT:
		return "Reset must restore crawler to AMBIENT"
	if crawler.current_durability != 2:
		return "Reset must restore crawler durability to 2"
	if crawler.is_harvested or crawler.is_rammed:
		return "Reset must restore is_harvested and is_rammed to false"
	if not crawler.debris_instances.is_empty():
		return "Reset must clear all debris instances"
	if crawler.beacon_light and crawler.beacon_light.light_energy < 1.0:
		return "Reset must restore amber beacon light energy"

	return ""
