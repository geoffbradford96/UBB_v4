extends SubViewportContainer

var main_camera: Camera3D

func _ready():
	await get_tree().process_frame
	main_camera = get_tree().current_scene.get_node_or_null("ArenaCamera")
	if not main_camera:
		main_camera = get_tree().current_scene.get_node_or_null("Camera3D")

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not main_camera or not is_instance_valid(main_camera):
			main_camera = get_tree().current_scene.get_node_or_null("ArenaCamera")
		if main_camera and main_camera.has_method("snap_to"):
			var x_percent = event.position.x / size.x
			var y_percent = event.position.y / size.y
			var map_range = 150.0 if GameState.map_selected == "Arena_6P.tscn" else 100.0
			var world_x = (x_percent * (map_range * 2.0)) - map_range
			var world_z = (y_percent * (map_range * 2.0)) - map_range
			main_camera.snap_to(Vector3(world_x, 0, world_z))
