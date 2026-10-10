extends Control

var _transitioned: bool = false

func _ready():
	print("Booting up...")
	# Wait for 2 seconds (simulate loading or showing a logo)
	await get_tree().create_timer(2.0).timeout
	_proceed()

func _input(event):
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if event.is_pressed():
			_proceed()

func _proceed():
	if _transitioned: return
	_transitioned = true
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
