extends Control

func _on_online_play_pressed():
	GameState.current_mode = "ONLINE"
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _on_local_play_pressed():
	GameState.current_mode = "LOCAL"
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _on_private_games_pressed():
	get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")

func _on_settings_pressed():
	GameState.previous_menu = "res://Scenes/MainMenu.tscn"
	get_tree().change_scene_to_file("res://Scenes/SettingsMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()
