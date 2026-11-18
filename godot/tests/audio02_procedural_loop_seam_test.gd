extends SceneTree

# Audio Production 02: the procedural fallback's short repeating loops must not
# produce a full-scale discontinuity at wrap. This checks PCM boundaries only,
# not headphone quality or mixed-output loudness.
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")


func _init() -> void:
	call_deferred("_run")


func _sample_signed(byte_value: int) -> int:
	return byte_value - 256 if byte_value > 127 else byte_value


func _check_loop(label: String, stream: AudioStreamWAV, duration: float) -> bool:
	if stream == null or stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		push_error("%s: expected looping WAV" % label)
		return false
	if stream.format != AudioStreamWAV.FORMAT_8_BITS or stream.mix_rate != 22050:
		push_error("%s: fallback format changed" % label)
		return false

	var data: PackedByteArray = stream.data
	if data.size() != int(22050.0 * duration) or stream.loop_begin != 0 or stream.loop_end != data.size():
		push_error("%s: loop sample bounds changed" % label)
		return false
	if _sample_signed(data[0]) != 0 or _sample_signed(data[data.size() - 1]) != 0:
		push_error("%s: first and last PCM samples are nonzero; wrap can click" % label)
		return false

	# Seam treatment must not silence the entire cue or change its useful body.
	var nonzero_interior := 0
	for index in range(256, data.size() - 256, 29):
		if absi(_sample_signed(data[index])) >= 2:
			nonzero_interior += 1
	if nonzero_interior < 100:
		push_error("%s: body of the loop became inaudibly weak" % label)
		return false
	return true


func _run() -> void:
	seed(102030)
	var manager: AudioManager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame

	var noise: AudioStreamWAV = manager.call("_create_noise_wav", 0.5, 0.4)
	var carrier: AudioStreamWAV = manager.call("_create_fractured_carrier_wav", 1.0, 0.3)
	var noise_ok := _check_loop("ambient/noise", noise, 0.5)
	var carrier_ok := _check_loop("radio/interference", carrier, 1.0)

	# Check the actual connected vehicle and threat loops, not synthetic test
	# fixtures. Nonintegral 0.8-second oscillator cycles previously caused a
	# repeating wrap discontinuity during ordinary riding.
	var siren := manager.get_node_or_null("SirenAlarmPlayer") as AudioStreamPlayer3D
	var idle := manager.get_node_or_null("EngineIdlePlayer") as AudioStreamPlayer3D
	var rev := manager.get_node_or_null("EngineRevTexturePlayer") as AudioStreamPlayer3D
	var coast := manager.get_node_or_null("EngineCoastPlayer") as AudioStreamPlayer3D
	var hum := manager.get_node_or_null("ProximityHumPlayer") as AudioStreamPlayer3D
	var tonal_nodes: Array[AudioStreamPlayer3D] = [siren, idle, rev, coast, hum]
	var tonal_labels := ["threat/siren", "vehicle/idle", "vehicle/rev", "vehicle/coast", "world/hum"]
	var durations := [0.6, 0.8, 0.8, 0.8, 0.5]
	var tonal_ok := true
	for i in range(tonal_nodes.size()):
		if tonal_nodes[i] == null:
			push_error("%s: required runtime loop absent" % tonal_labels[i])
			tonal_ok = false
			continue
		tonal_ok = _check_loop(tonal_labels[i], tonal_nodes[i].stream as AudioStreamWAV, durations[i]) and tonal_ok

	# Preserve the immediate attack of the non-looping short UI/interaction
	# tone helper. The new edge treatment is for continuous loops only.
	var transient: AudioStreamWAV = manager.call("_create_tone_wav", 310.0, 0.05, 0.30)
	var transient_ok := transient.loop_mode != AudioStreamWAV.LOOP_FORWARD and absi(_sample_signed(transient.data[1])) >= 2
	if not transient_ok:
		push_error("Short tonal transients must retain their immediate attack")

	manager.queue_free()
	await process_frame
	if not noise_ok or not carrier_ok or not tonal_ok or not transient_ok:
		quit(1)
		return
	print("AUDIO02_PROCEDURAL_LOOP_SEAM_PASS: noise, radio, siren, bike, hum wraps; transient attack retained")
	quit(0)
