@tool
extends Control

var portal_tools_plugin  # cannot type hint because cyclic

var _output_dir: String = ""
var _current_export_level_path: String = ""

var _config: Dictionary = {}
var _levels: Array[String] = []

@onready var setup: Button = %Setup_Button
@onready var export_level: Button = %ExportLevel_Button
@onready var open_exports: Button = %OpenExports_Button
@onready var export_level_label: Label = %ExportLevel_Label


func _ready() -> void:
	_config = PortalPlugin.read_config()
	if _config.size() == 0:
		return

	_output_dir = _config["export"]

	if not _config["setupEnabled"]:
		setup.disabled = true
		setup.tooltip_text = "Setup has been disabled. Check the config for any misconfiguration"
	else:
		setup.disabled = false
		setup.tooltip_text = "Setup python and virtual environment"

	_levels = _get_all_levels(_config)

	if not setup.pressed.is_connected(_setup):
		setup.pressed.connect(_setup)
	if not export_level.pressed.is_connected(_export_levels):
		export_level.pressed.connect(_export_levels)
	if not open_exports.pressed.is_connected(_on_open_exports):
		open_exports.pressed.connect(_on_open_exports)


func is_scene_a_level(scene: Node) -> bool:
	if scene is not Node3D:
		return false
	return scene.name in _levels


func change_scene(scene: Node) -> void:
	if not is_scene_a_level(scene):
		return
	var path = scene.scene_file_path
	_current_export_level_path = path
	var level_name = path.get_file().rstrip(".tscn")
	export_level_label.text = level_name
	export_level.disabled = false


func _setup() -> void:
	if not _config["setupEnabled"]:
		return

	portal_tools_plugin.show_log_panel()

	# forced to be on main thread
	print("Generating object library")
	var library_path = GenerateLibraryScript.generate_library()
	var scene_library: SceneLibrary = portal_tools_plugin.get_scene_library_instance()
	if scene_library != null:
		scene_library.load_library(library_path)
	
	print("Completed generating object library")


func _export_levels() -> void:
	var dialog = AcceptDialog.new()
	var output = []

	var export_tscn = "gdconverter/export_tscn"
	var scene_path = ProjectSettings.globalize_path(_current_export_level_path)
	var level_name = scene_path.get_file().get_basename()
	EditorInterface.save_scene()
	var fb_export_dir = _config["fbExportData"]

	var dialog_text = ""
	var exit_code = OS.execute(export_tscn, [scene_path, fb_export_dir, _output_dir], output, true)
	if exit_code != 0:
		dialog.title = "Error"
		dialog_text = "Failed to export %s\n" % level_name
		var err: String = (output.pop_back() as String).replace("\r\n", "\n").strip_edges()
		if err:
			var err_lines = err.split("\n", true)
			var line_count_limit = 15
			if err_lines.size() > line_count_limit:
				var err_truncated = err_lines.slice(0, line_count_limit)
				dialog_text += "\n".join(err_truncated)
				dialog_text += "\n...\n(see Output window for more details)"
			else:
				dialog_text += err
			portal_tools_plugin.show_log_panel()
			printerr(err)
	else:
		dialog.title = "Success"
		dialog_text = "Successfully exported %s" % level_name
	dialog.dialog_text = dialog_text
	EditorInterface.popup_dialog_centered(dialog)


func _on_open_exports() -> void:
	if not DirAccess.dir_exists_absolute(_output_dir):
		DirAccess.make_dir_recursive_absolute(_output_dir)

	if _current_export_level_path:
		var file = _current_export_level_path.get_file()
		var json_file = file.replace(".tscn", ".json")
		var supposed_path = _output_dir + "/" + json_file
		if FileAccess.file_exists(supposed_path):
			OS.shell_show_in_file_manager(supposed_path)
			return
	OS.shell_show_in_file_manager(_output_dir)


func _get_all_levels(config: Dictionary) -> Array[String]:
	if not "fbExportData" in config:
		return []

	var fb_data = config["fbExportData"]
	var level_info_path = fb_data + "/level_info.json"
	var file = FileAccess.open(level_info_path, FileAccess.READ)
	if file == null:
		printerr("Unable to read path: %s" % level_info_path)
		return []
	var contents = file.get_as_text()

	var level_info: Dictionary = JSON.parse_string(contents)
	var levels: Array[String] = []
	for level_name in level_info:
		levels.append(level_name)
	return levels
