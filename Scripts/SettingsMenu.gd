extends Control

@onready var resolution_option = $CenterContainer/VBoxContainer/HBoxRes/ResolutionDropdown
@onready var fullscreen_check = $CenterContainer/VBoxContainer/HBoxFull/FullscreenCheck
@onready var volume_slider = $CenterContainer/VBoxContainer/HBoxVol/VolumeSlider
@onready var corpse_limit_dropdown = $CenterContainer/VBoxContainer/HBoxCorpseLimit/CorpseLimitDropdown
@onready var corpse_duration_dropdown = $CenterContainer/VBoxContainer/HBoxCorpseDuration/CorpseDurationDropdown

var resolutions = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720)
]

var corpse_limits = [10, 30, 60, 120]
var corpse_limit_labels = ["Low (10 max)", "Medium (30 max)", "High (60 max)", "Ultra (120 max)"]

var corpse_durations = [5.0, 15.0, 30.0, 60.0, -1.0]
var corpse_duration_labels = ["Short (5s)", "Standard (15s)", "Long (30s)", "Extended (60s)", "Permanent"]

func _ready():
	# Populate Resolution Dropdown
	for res in resolutions:
		resolution_option.add_item(str(res.x) + " x " + str(res.y))
		
	# Set current resolution in dropdown
	var current_size = DisplayServer.window_get_size()
	var closest_idx = 0
	var min_diff = 999999
	for i in range(resolutions.size()):
		var diff = abs(resolutions[i].x - current_size.x) + abs(resolutions[i].y - current_size.y)
		if diff < min_diff:
			min_diff = diff
			closest_idx = i
	resolution_option.select(closest_idx)
	
	# Set current fullscreen state
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	# Set current volume
	var db = AudioServer.get_bus_volume_db(0) # Master bus
	volume_slider.value = db_to_linear(db)
	
	# Populate Corpse Dropdowns
	for lbl in corpse_limit_labels:
		corpse_limit_dropdown.add_item(lbl)
	for lbl in corpse_duration_labels:
		corpse_duration_dropdown.add_item(lbl)
		
	var lim_idx = corpse_limits.find(GameState.corpse_max_count)
	corpse_limit_dropdown.select(lim_idx if lim_idx != -1 else 1)
	
	var dur_idx = corpse_durations.find(GameState.corpse_duration)
	corpse_duration_dropdown.select(dur_idx if dur_idx != -1 else 1)
	
	_load_settings()

func _load_settings():
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		var vol = cfg.get_value("audio", "master_volume", 1.0)
		volume_slider.value = vol
		_on_volume_value_changed(vol)
		
		var fs = cfg.get_value("video", "fullscreen", false)
		fullscreen_check.button_pressed = fs
		_on_fullscreen_toggled(fs)
		
		var res_idx = cfg.get_value("video", "resolution_idx", resolution_option.selected)
		if res_idx >= 0 and res_idx < resolutions.size():
			resolution_option.select(res_idx)
			_on_resolution_item_selected(res_idx)
			
		var c_lim = cfg.get_value("gameplay", "corpse_max_count", GameState.corpse_max_count)
		GameState.corpse_max_count = c_lim
		var lim_idx = corpse_limits.find(c_lim)
		if lim_idx != -1: corpse_limit_dropdown.select(lim_idx)
		
		var c_dur = cfg.get_value("gameplay", "corpse_duration", GameState.corpse_duration)
		GameState.corpse_duration = c_dur
		var dur_idx = corpse_durations.find(c_dur)
		if dur_idx != -1: corpse_duration_dropdown.select(dur_idx)

func _save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master_volume", volume_slider.value)
	cfg.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	cfg.set_value("video", "resolution_idx", resolution_option.selected)
	cfg.set_value("gameplay", "corpse_max_count", GameState.corpse_max_count)
	cfg.set_value("gameplay", "corpse_duration", GameState.corpse_duration)
	cfg.save("user://settings.cfg")

func _on_resolution_item_selected(index):
	var target_res = resolutions[index]
	DisplayServer.window_set_size(target_res)
	# Center the window if we are not in fullscreen
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		var screen_size = DisplayServer.screen_get_size()
		var center_pos = (screen_size - target_res) / 2
		DisplayServer.window_set_position(center_pos)
	_save_settings()

func _on_fullscreen_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Trigger re-center
		_on_resolution_item_selected(resolution_option.selected)
	_save_settings()

func _on_volume_value_changed(value):
	# Linear to dB
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(0, db)
	# Mute if value is very low
	AudioServer.set_bus_mute(0, value <= 0.01)
	_save_settings()

func _on_corpse_limit_selected(index):
	if index >= 0 and index < corpse_limits.size():
		GameState.corpse_max_count = corpse_limits[index]
	_save_settings()

func _on_corpse_duration_selected(index):
	if index >= 0 and index < corpse_durations.size():
		GameState.corpse_duration = corpse_durations[index]
	_save_settings()

func _on_back_pressed():
	_save_settings()
	var dest = GameState.previous_menu if ("previous_menu" in GameState and GameState.previous_menu != "") else "res://Scenes/MainMenu.tscn"
	get_tree().change_scene_to_file(dest)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


