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
		exit_btn.connect("pressed", Callable(self, "_on_exit_button_pressed"))
		
	crosshair = ColorRect.new()
	crosshair.color = Color(1, 1, 1, 0.8)
	crosshair.custom_minimum_size = Vector2(8, 8)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.visible = false
	add_child(crosshair)

func _input(event):
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
	get_tree().paused = false
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer = null
	if GameState.current_mode == "ONLINE_HOST" or GameState.current_mode == "ONLINE_JOIN":
		get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func update_requisition(current: float, max_req: float):
	req_bar.max_value = max_req
	req_bar.value = current
	req_label.text = "Requisition: " + str(floor(current)) + " / " + str(max_req)
