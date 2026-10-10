extends Control

func _on_deck_making_pressed():
	get_tree().change_scene_to_file("res://Scenes/ArmyGathering.tscn")

func _on_war_games_pressed():
	get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")

func _on_ai_vs_ai_pressed():
	GameState.current_mode = "LOCAL"
	get_tree().change_scene_to_file("res://Scenes/MatchSetup.tscn")

func _on_settings_pressed():
	GameState.previous_menu = "res://Scenes/ModeHub.tscn"
	get_tree().change_scene_to_file("res://Scenes/SettingsMenu.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
