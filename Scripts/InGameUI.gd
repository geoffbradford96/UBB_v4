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
	
	var exit_btn = get_node_or_null("ExitButton")
	if exit_btn:
		exit_btn.text = "Exit Match"
		exit_btn.connect("pressed", Callable(self, "_on_exit_button_pressed"))
	
	if GameState.current_mode == "AI_VS_AI":
		var bp = get_node_or_null("BottomPanel")
		if bp: bp.visible = false
		_build_spectator_hud()
		_build_pause_menu()
		return
	
	if GameState.player_decks.has(player_profile) and GameState.player_decks[player_profile].size() > 0:
		deck = GameState.player_decks[player_profile].duplicate()
	else:
		deck = ["CommanderCard", "CheapGruntCard", "SupportingFireCard", "MedicCard", "CallArtilleryCard", "SniperCard"]
		
	deck.shuffle()
	for card_ui in hand_container.get_children():
		card_ui.connect("card_clicked", Callable(self, "_on_card_clicked"))
		draw_card(card_ui)
		
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
		
	if GameState.current_mode == "AI_VS_AI":
		if event is InputEventKey and event.keycode == KEY_V and event.pressed and not event.echo:
			call_deferred("_update_vision_btn_text")
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

var warning_label: Label = null
var warning_tween: Tween = null

func show_placement_warning(msg: String):
	if not warning_label:
		warning_label = Label.new()
		warning_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		warning_label.offset_top = -290
		warning_label.offset_bottom = -260
		warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		warning_label.add_theme_font_size_override("font_size", 16)
		warning_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		warning_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		warning_label.add_theme_constant_override("outline_size", 4)
		warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(warning_label)
		
	warning_label.text = msg
	warning_label.modulate.a = 1.0
	warning_label.visible = true
	
	if warning_tween and warning_tween.is_valid():
		warning_tween.kill()
	warning_tween = create_tween()
	warning_tween.tween_interval(1.2)
	warning_tween.tween_property(warning_label, "modulate:a", 0.0, 0.4)
	warning_tween.tween_callback(Callable(warning_label, "hide"))

var spectator_panel: Control = null
var spectator_a_bar: ProgressBar = null
var spectator_b_bar: ProgressBar = null
var spectator_a_label: Label = null
var spectator_b_label: Label = null
var spectator_vision_btn: Button = null

func _build_spectator_hud():
	spectator_panel = Control.new()
	spectator_panel.name = "SpectatorHUD"
	spectator_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	spectator_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spectator_panel)
	
	# 1. Top Panel: Dual Team Energy Bars (Side A Blue vs Side B Red)
	var top_panel = PanelContainer.new()
	top_panel.name = "SpectatorTopPanel"
	top_panel.offset_left = 130.0
	top_panel.offset_top = 14.0
	top_panel.offset_right = 620.0
	top_panel.offset_bottom = 68.0
	top_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	spectator_panel.add_child(top_panel)
	
	var top_vbox = VBoxContainer.new()
	top_vbox.add_theme_constant_override("separation", 4)
	top_panel.add_child(top_vbox)
	
	var mode_title = Label.new()
	mode_title.text = "SPECTATOR MODE - OBSERVING MATCH"
	mode_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_title.add_theme_font_size_override("font_size", 12)
	mode_title.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	top_vbox.add_child(mode_title)
	
	var dual_hbox = HBoxContainer.new()
	dual_hbox.add_theme_constant_override("separation", 16)
	top_vbox.add_child(dual_hbox)
	
	# Side A Box
	var a_vbox = VBoxContainer.new()
	a_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dual_hbox.add_child(a_vbox)
	
	spectator_a_label = Label.new()
	spectator_a_label.text = "Side A Energy: 0 / 100"
	spectator_a_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spectator_a_label.add_theme_font_size_override("font_size", 11)
	spectator_a_label.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0))
	a_vbox.add_child(spectator_a_label)
	
	spectator_a_bar = ProgressBar.new()
	spectator_a_bar.custom_minimum_size = Vector2(0, 14)
	spectator_a_bar.show_percentage = false
	spectator_a_bar.max_value = 100.0
	spectator_a_bar.value = 0.0
	var a_bg = StyleBoxFlat.new()
	a_bg.bg_color = Color(0.08, 0.12, 0.18, 0.9)
	a_bg.corner_radius_top_left = 3; a_bg.corner_radius_top_right = 3
	a_bg.corner_radius_bottom_left = 3; a_bg.corner_radius_bottom_right = 3
	var a_fg = StyleBoxFlat.new()
	a_fg.bg_color = Color(0.2, 0.65, 1.0)
	a_fg.corner_radius_top_left = 3; a_fg.corner_radius_top_right = 3
	a_fg.corner_radius_bottom_left = 3; a_fg.corner_radius_bottom_right = 3
	spectator_a_bar.add_theme_stylebox_override("background", a_bg)
	spectator_a_bar.add_theme_stylebox_override("fill", a_fg)
	a_vbox.add_child(spectator_a_bar)
	
	# Side B Box
	var b_vbox = VBoxContainer.new()
	b_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dual_hbox.add_child(b_vbox)
	
	spectator_b_label = Label.new()
	spectator_b_label.text = "Side B Energy: 0 / 100"
	spectator_b_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spectator_b_label.add_theme_font_size_override("font_size", 11)
	spectator_b_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	b_vbox.add_child(spectator_b_label)
	
	spectator_b_bar = ProgressBar.new()
	spectator_b_bar.custom_minimum_size = Vector2(0, 14)
	spectator_b_bar.show_percentage = false
	spectator_b_bar.max_value = 100.0
	spectator_b_bar.value = 0.0
	var b_bg = StyleBoxFlat.new()
	b_bg.bg_color = Color(0.18, 0.08, 0.08, 0.9)
	b_bg.corner_radius_top_left = 3; b_bg.corner_radius_top_right = 3
	b_bg.corner_radius_bottom_left = 3; b_bg.corner_radius_bottom_right = 3
	var b_fg = StyleBoxFlat.new()
	b_fg.bg_color = Color(0.95, 0.25, 0.25)
	b_fg.corner_radius_top_left = 3; b_fg.corner_radius_top_right = 3
	b_fg.corner_radius_bottom_left = 3; b_fg.corner_radius_bottom_right = 3
	spectator_b_bar.add_theme_stylebox_override("background", b_bg)
	spectator_b_bar.add_theme_stylebox_override("fill", b_fg)
	b_vbox.add_child(spectator_b_bar)
	
	# 2. Bottom Toolbar: Perspective Toggles & Player Vision
	var bottom_container = CenterContainer.new()
	bottom_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_container.offset_top = -90.0
	bottom_container.offset_bottom = -16.0
	bottom_container.mouse_filter = Control.MOUSE_FILTER_PASS
	spectator_panel.add_child(bottom_container)
	
	var bot_vbox = VBoxContainer.new()
	bot_vbox.add_theme_constant_override("separation", 6)
	bottom_container.add_child(bot_vbox)
	
	var hints = Label.new()
	hints.text = "[WASD / Arrows]: Pan Camera  |  [Wheel]: Zoom In/Out  |  [1-3 / Tab / V]: Shortcuts"
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hints.add_theme_font_size_override("font_size", 12)
	hints.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 0.85))
	bot_vbox.add_child(hints)
	
	var btns_hbox = HBoxContainer.new()
	btns_hbox.add_theme_constant_override("separation", 10)
	bot_vbox.add_child(btns_hbox)
	
	var btn_side_a = Button.new()
	btn_side_a.text = "Side A View (1)"
	btn_side_a.add_theme_font_size_override("font_size", 13)
	btn_side_a.connect("pressed", Callable(self, "_on_spec_snap_a"))
	btns_hbox.add_child(btn_side_a)
	
	var btn_side_b = Button.new()
	btn_side_b.text = "Side B View (2)"
	btn_side_b.add_theme_font_size_override("font_size", 13)
	btn_side_b.connect("pressed", Callable(self, "_on_spec_snap_b"))
	btns_hbox.add_child(btn_side_b)
	
	var btn_overview = Button.new()
	btn_overview.text = "Overview (3)"
	btn_overview.add_theme_font_size_override("font_size", 13)
	btn_overview.connect("pressed", Callable(self, "_on_spec_snap_overview"))
	btns_hbox.add_child(btn_overview)
	
	var btn_cycle = Button.new()
	btn_cycle.text = "Cycle Unit (Tab)"
	btn_cycle.add_theme_font_size_override("font_size", 13)
	btn_cycle.connect("pressed", Callable(self, "_on_spec_cycle_unit"))
	btns_hbox.add_child(btn_cycle)
	
	spectator_vision_btn = Button.new()
	_update_vision_btn_text()
	spectator_vision_btn.add_theme_font_size_override("font_size", 13)
	spectator_vision_btn.connect("pressed", Callable(self, "_on_spec_toggle_vision"))
	btns_hbox.add_child(spectator_vision_btn)

func _update_vision_btn_text():
	if spectator_vision_btn:
		var v_state = "ON (V)" if GameState.player_vision_enabled else "OFF (V)"
		spectator_vision_btn.text = "Player Vision: " + v_state

func _get_active_cam():
	var cam = get_viewport().get_camera_3d()
	if not cam:
		cam = get_tree().current_scene.find_child("Camera3D", true, false)
	return cam

func _on_spec_snap_a():
	var cam = _get_active_cam()
	if cam and cam.has_method("snap_to_side_a"):
		cam.snap_to_side_a()

func _on_spec_snap_b():
	var cam = _get_active_cam()
	if cam and cam.has_method("snap_to_side_b"):
		cam.snap_to_side_b()

func _on_spec_snap_overview():
	var cam = _get_active_cam()
	if cam and cam.has_method("snap_to_overview"):
		cam.snap_to_overview()

func _on_spec_cycle_unit():
	var cam = _get_active_cam()
	if cam and cam.has_method("cycle_follow_target"):
		cam.cycle_follow_target()

func _on_spec_toggle_vision():
	var cam = _get_active_cam()
	if cam and cam.has_method("toggle_player_vision"):
		cam.toggle_player_vision()
	else:
		GameState.player_vision_enabled = not GameState.player_vision_enabled
		for u in get_tree().get_nodes_in_group("Targetable"):
			var hc = u.get_node_or_null("HealthComponent")
			if hc and hc.has_method("update_ground_marker_color"):
				hc.update_ground_marker_color()
	_update_vision_btn_text()

func update_spectator_energy(a_cur: float, b_cur: float, max_e: float):
	if spectator_a_bar and spectator_a_label:
		spectator_a_bar.max_value = max_e
		spectator_a_bar.value = a_cur
		spectator_a_label.text = "Side A Energy: " + str(floor(a_cur)) + " / " + str(floor(max_e))
	if spectator_b_bar and spectator_b_label:
		spectator_b_bar.max_value = max_e
		spectator_b_bar.value = b_cur
		spectator_b_label.text = "Side B Energy: " + str(floor(b_cur)) + " / " + str(floor(max_e))

