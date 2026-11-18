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
	var noise: AudioStreamWAV = manager.call("_create_noise_wav", 0.5, 0.4)
	var carrier: AudioStreamWAV = manager.call("_create_fractured_carrier_wav", 1.0, 0.3)
	var noise_ok := _check_loop("ambient/noise", noise, 0.5)
	var carrier_ok := _check_loop("radio/interference", carrier, 1.0)
	manager.free()
	if not noise_ok or not carrier_ok:
		quit(1)
		return
	print("AUDIO02_PROCEDURAL_LOOP_SEAM_PASS: quiet edges, unchanged body, correct loop bounds")
	quit(0)
