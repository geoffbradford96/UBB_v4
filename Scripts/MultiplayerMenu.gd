extends Control

@onready var status_label = $VBoxContainer.get_node_or_null("StatusLabel")
@onready var host_btn = $VBoxContainer/HostBtn
@onready var join_btn = $VBoxContainer/JoinBtn
@onready var ip_input = $VBoxContainer/IPInput

func _ready():
	# Clean up any lingering connections from previous sessions
	GameState.disconnect_multiplayer()
	
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

func _exit_tree():
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	if multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.disconnect(_on_connection_failed)
	if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)

func _on_host_pressed():
	if status_label:
		status_label.text = "Starting host server on port 8910..."
		status_label.modulate = Color(0.95, 0.85, 0.2)
		
	GameState.current_mode = "ONLINE_HOST"
	var err = GameState.host_game()
	if err == OK:
		GameState.load_decks()
		if status_label:
			status_label.text = "Host server ready! Loading arena..."
			status_label.modulate = Color(0.2, 1.0, 0.4)
		var target_map = GameState.map_selected if GameState.map_selected != "" else "Arena.tscn"
		get_tree().change_scene_to_file("res://Scenes/" + target_map)
	else:
		if status_label:
			status_label.text = "Failed to host: Port 8910 in use (Error " + str(err) + ")"
			status_label.modulate = Color(1.0, 0.3, 0.2)

func _on_join_pressed():
	var ip = ip_input.text.strip_edges() if ip_input else ""
	if ip == "":
		ip = "127.0.0.1"
		
	if status_label:
		status_label.text = "Connecting to " + ip + ":8910... Please wait."
		status_label.modulate = Color(0.95, 0.85, 0.2)
		
	host_btn.disabled = true
	join_btn.disabled = true
	
	GameState.current_mode = "ONLINE_JOIN"
	var err = GameState.join_game(ip)
	if err != OK:
		if status_label:
			status_label.text = "Failed to initialize client socket (Error " + str(err) + ")"
			status_label.modulate = Color(1.0, 0.3, 0.2)
		host_btn.disabled = false
		join_btn.disabled = false

func _on_connected_to_server():
	print("Connected to host server successfully!")
	if status_label:
		status_label.text = "Connected! Loading battle..."
		status_label.modulate = Color(0.2, 1.0, 0.4)
	GameState.load_decks()
	var target_map = GameState.map_selected if GameState.map_selected != "" else "Arena.tscn"
	get_tree().change_scene_to_file("res://Scenes/" + target_map)

func _on_connection_failed():
	print("Connection to host failed.")
	var ip = ip_input.text.strip_edges() if ip_input else "127.0.0.1"
	if ip == "": ip = "127.0.0.1"
	if status_label:
		status_label.text = "Connection failed! Host not reachable at " + ip + ":8910"
		status_label.modulate = Color(1.0, 0.3, 0.2)
	host_btn.disabled = false
	join_btn.disabled = false
	GameState.disconnect_multiplayer()

func _on_server_disconnected():
	print("Disconnected from server.")
	if status_label:
		status_label.text = "Server connection lost."
		status_label.modulate = Color(1.0, 0.3, 0.2)
	host_btn.disabled = false
	join_btn.disabled = false
	GameState.disconnect_multiplayer()

func _on_local_2p_pressed():
	GameState.current_mode = "LOCAL_SPLIT_2P"
	get_tree().change_scene_to_file("res://Scenes/Arena.tscn")
	
func _on_local_4p_pressed():
	GameState.current_mode = "LOCAL_SPLIT_4P"
	get_tree().change_scene_to_file("res://Scenes/Arena_4P.tscn")

func _on_back_pressed():
	GameState.disconnect_multiplayer()
	get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _on_ip_input_text_submitted(_new_text: String):
	_on_join_pressed()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
