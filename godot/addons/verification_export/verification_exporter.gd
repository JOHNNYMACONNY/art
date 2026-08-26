@tool
extends EditorExportPlugin

const SOURCE_DIR := "res://verification/current"
const EVIDENCE_FILES := [
	"01_quiet_traversal.png",
	"02_courier_bike.png",
	"03_pursuit.png",
	"04_shortcut_intersection.png",
	"05_burn_garage.png",
	"06_silent_core.png",
	"07_day.png",
	"08_dusk.png",
	"09_fb13_thrum.png",
	"verification_report.json",
]

var _active := false
var _export_path := ""

func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform.get_os_name() == "Web"

func _export_begin(_features: PackedStringArray, _is_debug: bool, path: String, _flags: int) -> void:
	_export_path = path
	# _supports_platform() limits this plugin to the Web export platform. CI is
	# the second gate so ordinary local editor/export use remains unaffected.
	_active = OS.get_environment("GITHUB_ACTIONS").to_lower() == "true"
	if not _active:
		return

	var executable := OS.get_executable_path()
	var project_dir := ProjectSettings.globalize_path("res://")
	var output: Array = []
	var arguments := PackedStringArray([
		"-a",
		"-s",
		"-screen 0 1280x720x24",
		executable,
		"--path",
		project_dir,
		"--rendering-method",
		"gl_compatibility",
		"--script",
		"res://tests/gears_verification_capture.gd",
	])
	print("[VERIFICATION_EXPORT] Launching exact-project Xvfb capture before Web export")
	var exit_code := OS.execute("xvfb-run", arguments, output, true)
	for line in output:
		print(str(line))
	assert(exit_code == 0, "Rendered verification capture failed with exit code %s" % exit_code)

	for file_name in EVIDENCE_FILES:
		var source_path := SOURCE_DIR + "/" + file_name
		assert(FileAccess.file_exists(source_path), "Required verification evidence missing: %s" % source_path)

	var report_text := FileAccess.get_file_as_string(SOURCE_DIR + "/verification_report.json")
	var report = JSON.parse_string(report_text)
	assert(report is Dictionary, "Verification report is not valid JSON")
	var expected_sha := OS.get_environment("SOURCE_SHA")
	if not expected_sha.is_empty():
		assert(str(report.get("source_sha", "")) == expected_sha, "Verification report SHA does not match exact export source")

func _export_end() -> void:
	if not _active:
		return
	var destination_dir := _export_path.get_base_dir().path_join("verification")
	var dir_error := DirAccess.make_dir_recursive_absolute(destination_dir)
	assert(dir_error == OK or dir_error == ERR_ALREADY_EXISTS, "Could not create Web verification evidence directory")

	for file_name in EVIDENCE_FILES:
		var source_path := SOURCE_DIR + "/" + file_name
		var destination_path := destination_dir.path_join(file_name)
		var bytes := FileAccess.get_file_as_bytes(source_path)
		assert(bytes.size() > 0, "Verification evidence is empty: %s" % file_name)
		var destination := FileAccess.open(destination_path, FileAccess.WRITE)
		assert(destination != null, "Could not write Web verification evidence: %s" % destination_path)
		destination.store_buffer(bytes)
		destination.close()
		assert(FileAccess.file_exists(destination_path), "Web verification evidence copy failed: %s" % destination_path)

	print("[VERIFICATION_EXPORT] Published %s verification files beside Web playtest" % EVIDENCE_FILES.size())
	_active = false
