extends Control

func _ready():
	print("Booting up...")
	# Wait for 2 seconds (simulate loading or showing a logo)
	await get_tree().create_timer(2.0).timeout
	
	# Automatically transition to the Main Menu
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
