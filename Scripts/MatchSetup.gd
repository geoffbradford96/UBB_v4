extends Control

@onready var role_option = $CenterContainer/VBoxContainer/HBoxRole/RoleDropdown
@onready var map_option = $CenterContainer/VBoxContainer/HBoxMap/MapDropdown
@onready var mode_option = $CenterContainer/VBoxContainer/HBoxMode/ModeDropdown
@onready var players_option = $CenterContainer/VBoxContainer/HBoxPlayers/PlayersDropdown
@onready var diff_option = $CenterContainer/VBoxContainer/HBoxDiff/DiffDropdown
@onready var timer_option = $CenterContainer/VBoxContainer/HBoxTimer/TimerDropdown

func _ready():
	role_option.add_item("Play as Player 1")
	role_option.add_item("Spectate (AI vs AI)")
	
	map_option.add_item("1v1 Map")
	map_option.add_item("4-Player Map")
	map_option.add_item("3v3 KOTH Map")
	
	mode_option.add_item("Destroy Base")
	mode_option.add_item("King of the Hill")
	
	
	diff_option.add_item("Easy")
	diff_option.add_item("Medium")
	diff_option.add_item("Hard")
	diff_option.select(1) # Default to Medium
	
	timer_option.add_item("2.5 Minutes") # 0
	timer_option.add_item("5 Minutes")   # 1
	timer_option.add_item("10 Minutes")  # 2
	timer_option.add_item("15 Minutes")  # 3
	timer_option.add_item("20 Minutes")  # 4
	timer_option.add_item("25 Minutes")  # 5
	timer_option.add_item("30 Minutes")  # 6
	timer_option.add_item("35 Minutes")  # 7
	timer_option.add_item("40 Minutes")  # 8
	timer_option.add_item("45 Minutes")  # 9
	timer_option.add_item("50 Minutes")  # 10
	timer_option.add_item("55 Minutes")  # 11
	timer_option.add_item("60 Minutes")  # 12
	timer_option.select(2) # Default 10 min
	_update_players_dropdown(0)
	
func _update_players_dropdown(map_index: int):
	players_option.clear()
	if map_index == 2:
		players_option.add_item("6 Players")
		timer_option.select(4) # Default 20 min for 6p
	else:
		players_option.add_item("2 Players")
		if map_index == 1:
			players_option.add_item("3 Players")
			players_option.add_item("4 Players")
		timer_option.select(2) # Default 10 min for <= 4p
		
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
	
	var time_map = {0: 150.0, 1: 300.0, 2: 600.0, 3: 900.0, 4: 1200.0, 5: 1500.0, 6: 1800.0, 7: 2100.0, 8: 2400.0, 9: 2700.0, 10: 3000.0, 11: 3300.0, 12: 3600.0}
	GameState.sudden_death_timer = time_map[timer_option.selected]
	
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/" + GameState.map_selected)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")
