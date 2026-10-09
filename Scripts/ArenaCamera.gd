extends Camera3D

@export var player_id: int = 1 # 1, 2, 3, or 4
@export var assigned_team: String = "SideA"

var target_position: Vector3 = Vector3.ZERO
var is_snapped: bool = false
var hero: Node3D = null

var zoom_level: float = 1.0
var min_zoom: float = 0.5
var max_zoom: float = 3.0

func _ready():
	target_position = Vector3(0, 0, 0)
	is_snapped = true

func _process(delta):
	# Find the Commander if we don't have one and we're not manually exploring
	if hero == null or not is_instance_valid(hero):
		var potential_heroes = get_tree().get_nodes_in_group(assigned_team)
		for p in potential_heroes:
			if p.is_in_group("CommanderUnit") or "Commander" in p.name or "Overlord" in p.name or "GreatBeastSpeaker" in p.name:
				hero = p
				return_to_hero()
				break
	
	# Handle input using our dynamic mapped inputs (p1_up, p2_up, etc)
	var move_dir = Vector3.ZERO
	var prefix = "p" + str(player_id) + "_"
	
	if Input.is_action_pressed(prefix + "up"): move_dir.z -= 1
	if Input.is_action_pressed(prefix + "down"): move_dir.z += 1
	if Input.is_action_pressed(prefix + "left"): move_dir.x -= 1
	if Input.is_action_pressed(prefix + "right"): move_dir.x += 1
		
	if move_dir != Vector3.ZERO:
		if not is_snapped and hero != null and is_instance_valid(hero):
			target_position = hero.global_position
		is_snapped = true
		target_position += move_dir.normalized() * 40.0 * delta
		
	var max_pan = 160.0 if GameState.map_selected == "Arena_6P.tscn" else (110.0 if GameState.map_selected == "Arena_4P.tscn" else 90.0)
	target_position.x = clamp(target_position.x, -max_pan, max_pan)
	target_position.z = clamp(target_position.z, -max_pan, max_pan)
				
	var camera_offset = Vector3(0, 20.0 * zoom_level, 16.0 * zoom_level)
	
	if is_snapped:
		global_position = global_position.lerp(target_position + camera_offset, 10.0 * delta)
	elif hero != null and is_instance_valid(hero):
		global_position = global_position.lerp(hero.global_position + camera_offset, 10.0 * delta)

func return_to_hero():
	is_snapped = false

func _unhandled_input(event):
	var prefix = "p" + str(player_id) + "_"
	
	if event.is_action_pressed(prefix + "action"):
		return_to_hero()
		
	# Quick zoom check (mostly for mouse, hard to split mouse wheel per player but we keep it here)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = clamp(zoom_level - 0.1, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = clamp(zoom_level + 0.1, min_zoom, max_zoom)

func snap_to(pos: Vector3):
	target_position = pos
	is_snapped = true
