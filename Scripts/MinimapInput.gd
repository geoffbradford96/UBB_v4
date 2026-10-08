extends SubViewportContainer

var main_camera: Camera3D

func _ready():
	# Wait a frame for the scene to fully load, then find the main camera
	await get_tree().process_frame
	main_camera = get_tree().current_scene.get_node_or_null("Camera3D")

func _gui_input(event):
	# If the player clicks on the minimap
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if main_camera:
			# Calculate where they clicked relative to the Minimap size (0.0 to 1.0)
			var x_percent = event.position.x / size.x
			var y_percent = event.position.y / size.y
			
			# Map that percentage to our actual 200x200 3D Arena floor (-100 to 100)
			var world_x = (x_percent * 200.0) - 100.0
			var world_z = (y_percent * 200.0) - 100.0
			
			# Tell the camera to fly there!
			main_camera.snap_to(Vector3(world_x, 0, world_z))
