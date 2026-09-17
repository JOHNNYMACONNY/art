extends RefCounted

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const MemoryEchoController = preload("res://scripts/prototype/memory_echo_controller.gd")
const ScrapHaulerScript = preload("res://scripts/vehicles/scrap_hauler.gd")
const ScrapWorkerScript = preload("res://scripts/entities/scrap_worker.gd")
const UtilityCrawlerScript = preload("res://scripts/entities/utility_crawler.gd")
const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const RadioProgramDirectorScript = preload("res://scripts/audio/radio/radio_program_director.gd")
const RadioProgramPlayerScript = preload("res://scripts/audio/radio/radio_program_player.gd")
const CourierBikeScript = preload("res://scripts/vehicles/courier_bike.gd")
const PursuerPrototypeScript = preload("res://scripts/entities/pursuer_prototype.gd")
const SignalGateInteractableScript = preload("res://scripts/interactions/signal_gate_interactable.gd")
const SignalTunerScript = preload("res://scripts/interactions/signal_tuner.gd")
const CorrodedPanelScript = preload("res://scripts/interactions/corroded_panel.gd")
const TestHelpers = preload("res://tests/embedded/test_helpers.gd")

static func export_v8_proof(controller: ScrapTestBlock) -> void:
	print("[V8_STYLE_PROOF] Exporting V8 Style Proof views to res://verification/v8/v8_proof_*.png...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.2).timeout
	
	# View 1: Cold start staging (Player, Container, Scrap Pile, Ground Debris)
	controller.player.global_position = Vector3(0, 0.4, 10.0)
	controller.player.velocity = Vector3.ZERO
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_proof_01_cold_start.png")
	print("[V8_STYLE_PROOF] Saved v8_proof_01_cold_start.png")
	
	# View 2: Tuner approach staging (Player approaching Tuner with East Scrap Pile and Ground Debris)
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 1.8)
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_proof_02_tuner_approach.png")
	print("[V8_STYLE_PROOF] Saved v8_proof_02_tuner_approach.png")
	
	# View 3: Modular Kit Lineup (Staging Pad with Pipe Rack, Corrugated Fence, Courier Bike)
	controller.player.global_position = Vector3(1.5, 0.4, 6.0)
	controller.courier_bike.global_position = controller._recovery_marker
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_proof_03_modular_kit_lineup.png")
	print("[V8_STYLE_PROOF] Saved v8_proof_03_modular_kit_lineup.png")
	
	print("[V8_STYLE_PROOF] ALL V8 STYLE PROOF VIEWS EXPORTED CLEANLY!")
	controller.get_tree().quit(0)


static func export_v8_benchmarks(controller: ScrapTestBlock, prefix: String) -> void:
	print("[V8_BENCHMARKS] Exporting 8 required V8 visual benchmark views to res://verification/v8/%s_*.png..." % prefix)
	controller.reset_slice()
	await controller.get_tree().create_timer(0.2).timeout
	
	# 1. 01_cold_start.png
	controller.player.global_position = Vector3(0, 0.4, 10.0)
	controller.player.velocity = Vector3.ZERO
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/%s_01_cold_start.png" % prefix)
	print("[V8_BENCHMARKS] Saved view 01_cold_start")
	
	# 2. 02_tuner_approach.png
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 1.8)
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/%s_02_tuner_approach.png" % prefix)
	print("[V8_BENCHMARKS] Saved view 02_tuner_approach")
	
	# 3. 03_panel_extraction.png
	controller.player.global_position = controller.corroded_panel.global_position + Vector3(0, 0, 1.2)
	controller.corroded_panel.update_player_distance(controller.player.global_position)
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/%s_03_panel_extraction.png" % prefix)
	print("[V8_BENCHMARKS] Saved view 03_panel_extraction")
	
	# 4. 04_bike_staging.png
	controller.player.global_position = controller._recovery_marker + Vector3(0, 0, 1.5)
	controller.courier_bike.global_position = controller._recovery_marker
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/%s_04_bike_staging.png" % prefix)
	print("[V8_BENCHMARKS] Saved view 04_bike_staging")
	
	# 5. 05_gate_approach.png
	controller.courier_bike.global_position = controller.signal_gate.global_position + Vector3(0, 0, 6.0)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.player.global_position = controller.courier_bike.global_position
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/%s_05_gate_approach.png" % prefix)
	print("[V8_BENCHMARKS] Saved view 05_gate_approach")
	
	# 6. 06_shortcut_ramp.png
	controller.courier_bike.global_position = Vector3(4.0, 0.05, 14.0)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.player.global_position = controller.courier_bike.global_position
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/%s_06_shortcut_ramp.png" % prefix)
	print("[V8_BENCHMARKS] Saved view 06_shortcut_ramp")
	
	# 7. 07_active_chase.png
	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout
	controller.courier_bike.global_position = Vector3(0.0, 0.05, 20.0)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.player.global_position = controller.courier_bike.global_position
	controller.pursuer.global_position = Vector3(0.0, 0.05, 12.0)
	controller.audio_mgr.set_pursuit_pressure(8.0, controller.pursuer.global_position)
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/%s_07_active_chase.png" % prefix)
	print("[V8_BENCHMARKS] Saved view 07_active_chase")
	
	# 8. 08_quiet_aftermath.png
	controller._on_successful_evasion()
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/%s_08_quiet_aftermath.png" % prefix)
	print("[V8_BENCHMARKS] Saved view 08_quiet_aftermath")
	
	print("[V8_BENCHMARKS] ALL 8 %s BENCHMARKS EXPORTED CLEANLY!" % prefix)
	controller.get_tree().quit(0)


static func run_telemetry(controller: ScrapTestBlock) -> void:
	print("[V8_TELEMETRY] Gathering rendering and frame-timing telemetry...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	
	var frame_times: Array[float] = []
	for i in range(120):
		var t0: int = Time.get_ticks_usec()
		await controller.get_tree().process_frame
		var t1: int = Time.get_ticks_usec()
		frame_times.append(float(t1 - t0) / 1000.0)
	
	frame_times.sort()
	var avg_ms: float = 0.0
	for ft in frame_times:
		avg_ms += ft
	avg_ms /= float(frame_times.size())
	var p95_idx: int = int(float(frame_times.size()) * 0.95)
	var p95_ms: float = frame_times[p95_idx]
	
	var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var objects: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var vp_size: Vector2i = controller.get_viewport().size
	
	print("\n=========================================================================")
	print("[V8_TELEMETRY_REPORT]")
	print("  Viewport Size: %dx%d" % [vp_size.x, vp_size.y])
	print("  Rendering Method: Forward+")
	print("  Draw Calls: %d" % draw_calls)
	print("  Primitives/Triangles: %d" % primitives)
	print("  Total Objects: %d" % objects)
	print("  Average Frame Time: %.2f ms (%.1f FPS)" % [avg_ms, 1000.0 / max(avg_ms, 0.001)])
	print("  P95 Frame Time: %.2f ms" % p95_ms)
	print("=========================================================================\n")
	controller.get_tree().quit(0)


