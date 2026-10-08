extends Control

@onready var role_option = $CenterContainer/VBoxContainer/HBoxRole/RoleDropdown
@onready var map_option = $CenterContainer/VBoxContainer/HBoxMap/MapDropdown
@onready var mode_option = $CenterContainer/VBoxContainer/HBoxMode/ModeDropdown
@onready var players_option = $CenterContainer/VBoxContainer/HBoxPlayers/PlayersDropdown
@onready var diff_option = $CenterContainer/VBoxContainer/HBoxDiff/DiffDropdown

func _ready():
	role_option.add_item("Play as Player 1")
	role_option.add_item("Spectate (AI vs AI)")
	
	map_option.add_item("1v1 Map")
	map_option.add_item("4-Player Map")
	map_option.add_item("3v3 KOTH Map")
	
	mode_option.add_item("Destroy Base")
	mode_option.add_item("King of the Hill")
	
	_update_players_dropdown(0)
	
	diff_option.add_item("Easy")
	diff_option.add_item("Medium")
	diff_option.add_item("Hard")
	diff_option.select(1) # Default to Medium
	
func _update_players_dropdown(map_index: int):
	players_option.clear()
	if map_index == 2:
		players_option.add_item("6 Players")
	else:
		players_option.add_item("2 Players")
		if map_index == 1:
			players_option.add_item("3 Players")
			players_option.add_item("4 Players")
		
func _on_map_item_selected(index):
	_update_players_dropdown(index)

func _on_start_pressed():
	if map_option.selected == 0:
		GameState.map_selected = "Arena.tscn"
	elif map_option.selected == 1:
		GameState.map_selected = "Arena_4P.tscn"
	else:
		GameState.map_selected = "Arena_6P.tscn"
		
	if mode_option.selected == 0:
		GameState.game_mode = "DESTROY_BASE"
	else:
		GameState.game_mode = "KOTH"
		
	if role_option.selected == 0:
		GameState.current_mode = "LOCAL"
	else:
		GameState.current_mode = "AI_VS_AI"
		
	if GameState.map_selected == "Arena_6P.tscn":
		GameState.match_player_count = 6
	else:
		GameState.match_player_count = players_option.selected + 2 
	
	var diff = diff_option.selected
	if diff == 0: GameState.ai_difficulty = "EASY"
	elif diff == 1: GameState.ai_difficulty = "MEDIUM"
	else: GameState.ai_difficulty = "HARD"
	
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/" + GameState.map_selected)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")
