extends RefCounted

static func save_proof_png(c: ScrapTestBlock, path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var base_dir := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(base_dir)
	var vp := c.get_viewport()
	if vp:
		var tex := vp.get_texture()
		if tex:
			var img := tex.get_image()
			if img:
				img.save_png(path)
				return
	assert(false, "FAIL: Viewport texture image capture failed for path: %s" % path)

static func create_test_wav_file(path: String, num_samples: int = 1000) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return
	var data_size: int = num_samples * 2
	var total_size: int = 36 + data_size
	file.store_string("RIFF")
	file.store_32(total_size)
	file.store_string("WAVE")
	file.store_string("fmt ")
	file.store_32(16) # Subchunk1Size
	file.store_16(1)  # AudioFormat = 1 (PCM)
	file.store_16(1)  # NumChannels = 1 (Mono)
	file.store_32(22050) # SampleRate
	file.store_32(44100) # ByteRate = 22050 * 1 * 2
	file.store_16(2)  # BlockAlign = 1 * 2
	file.store_16(16) # BitsPerSample = 16
	file.store_string("data")
	file.store_32(data_size)
	for i in range(num_samples):
		var s: float = sin(float(i) * 0.1) * 15000.0
		file.store_16(int(s))
	file.close()
