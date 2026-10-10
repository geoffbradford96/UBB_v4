extends Control

@onready var req_bar = $BottomPanel/RequisitionBar
@onready var req_label = $BottomPanel/RequisitionBar/Label
@onready var hand_container = $BottomPanel/HandContainer

var deck: Array = []
var discard: Array = []

var input_mode: String = "MOUSE"
var crosshair: ColorRect
var selected_card_idx: int = -1

var device_id: int = -1
var player_id: int = 1 # -1 means Keyboard/Mouse + Controller 0.
var player_profile: String = "Player1"

signal ui_card_selected(card_ui, ui_instance)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if GameState.player_decks.has(player_profile) and GameState.player_decks[player_profile].size() > 0:
		deck = GameState.player_decks[player_profile].duplicate()
	else:
		deck = ["CommanderCard", "CheapGruntCard", "SupportingFireCard", "MedicCard", "CallArtilleryCard", "SniperCard"]
		
	deck.shuffle()
	for card_ui in hand_container.get_children():
		card_ui.connect("card_clicked", Callable(self, "_on_card_clicked"))
		draw_card(card_ui)
		
	var exit_btn = get_node_or_null("ExitButton")
	if exit_btn:
		if GameState.current_mode == "AI_VS_AI":
			exit_btn.text = "Exit Match"
		exit_btn.connect("pressed", Callable(self, "_on_exit_button_pressed"))
		
	# Create top panel for Enemy / Opponent Requisition display
	_build_enemy_req_ui()
	_build_pause_menu()
		
	crosshair = ColorRect.new()
	crosshair.color = Color(1, 1, 1, 0.8)
	crosshair.custom_minimum_size = Vector2(8, 8)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.visible = false
	add_child(crosshair)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()
		return
		
	if device_id != -1 and event.device != device_id:
		return
		
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		if input_mode != "MOUSE":
			input_mode = "MOUSE"
			crosshair.visible = false
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		if input_mode != "CONTROLLER":
			input_mode = "CONTROLLER"
			crosshair.visible = true
			if selected_card_idx == -1:
				selected_card_idx = 0
				_update_controller_selection()
				
	if input_mode == "CONTROLLER":
		var prefix = "p" + str(player_id) + "_"
		if event.is_action_pressed(prefix + "prev_card"):
			selected_card_idx -= 1
			if selected_card_idx < 0: selected_card_idx = hand_container.get_child_count() - 1
			_update_controller_selection()
		elif event.is_action_pressed(prefix + "next_card"):
			selected_card_idx += 1
			if selected_card_idx >= hand_container.get_child_count(): selected_card_idx = 0
			_update_controller_selection()

func _update_controller_selection():
	if selected_card_idx >= 0 and selected_card_idx < hand_container.get_child_count():
		var child = hand_container.get_child(selected_card_idx)
		emit_signal("ui_card_selected", child, self)

func draw_card(card_ui):
	if deck.is_empty() and discard.is_empty():
		return
	if deck.is_empty():
		deck = discard.duplicate()
		discard.clear()
		deck.shuffle()
		
	var card_name = deck.pop_front()
	var data = load("res://Data/Cards/" + card_name + ".tres")
	if data:
		card_ui.set_card_data(data)

func _on_card_clicked(card_ui):
	selected_card_idx = card_ui.get_index()
	emit_signal("ui_card_selected", card_ui, self)

func _on_exit_button_pressed():
	toggle_pause_menu()

var pause_overlay: Control = null
var pause_settings_container: VBoxContainer = null

func _build_pause_menu():
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.05, 0.08, 0.8)
	pause_overlay.add_child(dim)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 320)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	var title = Label.new()
	var is_online = multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	title.text = "MATCH OPTIONS" if is_online else "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var resume_btn = Button.new()
	resume_btn.text = "Resume Match"
	resume_btn.custom_minimum_size = Vector2(0, 42)
	resume_btn.add_theme_font_size_override("font_size", 18)
	resume_btn.connect("pressed", Callable(self, "toggle_pause_menu"))
	vbox.add_child(resume_btn)
	
	var settings_toggle_btn = Button.new()
	settings_toggle_btn.text = "Audio & Video Settings"
	settings_toggle_btn.custom_minimum_size = Vector2(0, 42)
	settings_toggle_btn.add_theme_font_size_override("font_size", 18)
	settings_toggle_btn.connect("pressed", Callable(self, "_toggle_pause_settings"))
	vbox.add_child(settings_toggle_btn)
	
	pause_settings_container = VBoxContainer.new()
	pause_settings_container.visible = false
	vbox.add_child(pause_settings_container)
	
	var vol_lbl = Label.new()
	vol_lbl.text = "Master Volume"
	pause_settings_container.add_child(vol_lbl)
	
	var vol_slider = HSlider.new()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	var cur_db = AudioServer.get_bus_volume_db(0)
	vol_slider.value = db_to_linear(cur_db)
	vol_slider.connect("value_changed", Callable(self, "_on_pause_vol_changed"))
	pause_settings_container.add_child(vol_slider)
	
	var fs_check = CheckBox.new()
	fs_check.text = "Fullscreen Mode"
	fs_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fs_check.connect("toggled", Callable(self, "_on_pause_fs_toggled"))
	pause_settings_container.add_child(fs_check)
	
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	var surrender_btn = Button.new()
	surrender_btn.text = "Surrender & Return to Hub"
	surrender_btn.custom_minimum_size = Vector2(0, 42)
	surrender_btn.add_theme_font_size_override("font_size", 18)
	surrender_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
	surrender_btn.connect("pressed", Callable(self, "_on_confirm_surrender"))
	vbox.add_child(surrender_btn)
	
	add_child(pause_overlay)

func toggle_pause_menu():
	if not pause_overlay: return
	var is_open = not pause_overlay.visible
	pause_overlay.visible = is_open
	
	var is_online = multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	if not is_online:
		get_tree().paused = is_open

func _toggle_pause_settings():
	if pause_settings_container:
		pause_settings_container.visible = not pause_settings_container.visible

func _on_pause_vol_changed(val: float):
	var db = linear_to_db(val)
	AudioServer.set_bus_volume_db(0, db)
	AudioServer.set_bus_mute(0, val <= 0.01)

func _on_pause_fs_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_confirm_surrender():
	if pause_overlay: pause_overlay.visible = false
	get_tree().paused = false
	GameState.disconnect_multiplayer()
	if GameState.current_mode == "ONLINE_HOST" or GameState.current_mode == "ONLINE_JOIN":
		get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")


var enemy_req_bar: ProgressBar = null
var enemy_req_label: Label = null

func _build_enemy_req_ui():
	var top_panel = PanelContainer.new()
	top_panel.name = "EnemyReqPanel"
	top_panel.offset_left = 130.0
	top_panel.offset_top = 18.0
	top_panel.offset_right = 370.0
	top_panel.offset_bottom = 62.0
	
	var vbox = VBoxContainer.new()
	top_panel.add_child(vbox)
	
	enemy_req_label = Label.new()
	enemy_req_label.text = "Enemy Energy: 0 / 100"
	enemy_req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_req_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(enemy_req_label)
	
	enemy_req_bar = ProgressBar.new()
	enemy_req_bar.custom_minimum_size = Vector2(230, 14)
	enemy_req_bar.show_percentage = false
	enemy_req_bar.max_value = 100.0
	enemy_req_bar.value = 0.0
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.1, 0.1, 0.85)
	style_bg.corner_radius_top_left = 4; style_bg.corner_radius_top_right = 4
	style_bg.corner_radius_bottom_left = 4; style_bg.corner_radius_bottom_right = 4
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.85, 0.25, 0.2)
	style_fill.corner_radius_top_left = 4; style_fill.corner_radius_top_right = 4
	style_fill.corner_radius_bottom_left = 4; style_fill.corner_radius_bottom_right = 4
	
	enemy_req_bar.add_theme_stylebox_override("background", style_bg)
	enemy_req_bar.add_theme_stylebox_override("fill", style_fill)
	vbox.add_child(enemy_req_bar)
	
	add_child(top_panel)

func update_requisition(current: float, max_req: float):
	req_bar.max_value = max_req
	req_bar.value = current
	var prefix = "SideA Energy" if GameState.current_mode == "AI_VS_AI" else "Requisition"
	req_label.text = prefix + ": " + str(floor(current)) + " / " + str(max_req)

func update_enemy_requisition(current: float, max_req: float, label_prefix: String = "Enemy"):
	if enemy_req_bar and enemy_req_label:
		enemy_req_bar.max_value = max_req
		enemy_req_bar.value = current
		enemy_req_label.text = label_prefix + " Energy: " + str(floor(current)) + " / " + str(max_req)
