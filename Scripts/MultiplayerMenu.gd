extends Control

func _on_host_pressed():
	print("Hosting server...")
	GameState.current_mode = "ONLINE_HOST"
	GameState.host_game()
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/Arena.tscn")

func _on_join_pressed():
	var ip = $VBoxContainer/IPInput.text
	if ip == "":
		ip = "127.0.0.1"
	print("Joining server at ", ip)
	GameState.current_mode = "ONLINE_JOIN"
	GameState.join_game(ip)
	GameState.load_decks()
	get_tree().change_scene_to_file("res://Scenes/Arena.tscn")

func _on_local_2p_pressed():
	GameState.current_mode = "LOCAL_SPLIT_2P"
	get_tree().change_scene_to_file("res://Scenes/Arena.tscn")
	
func _on_local_4p_pressed():
	GameState.current_mode = "LOCAL_SPLIT_4P"
	get_tree().change_scene_to_file("res://Scenes/Arena_4P.tscn")

func _on_back_pressed():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")
