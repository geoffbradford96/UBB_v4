extends CharacterBody3D

@export var unit_attribute: String = "Organic"

const SPEED = 5.0
const ATTACK_RANGE = 2.0

@export var is_player_controlled: bool = false
@export var attack_damage: float = 25.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.0

var current_target: Node3D = null
var attack_timer: float = 0.0

@onready var mesh = $MeshInstance3D

var walk_time: float = 0.0
var base_mesh_pos: Vector3 = Vector3.ZERO

func _ready():
	add_to_group("Targetable")
		# Dynamically assign attribute based on name if not set manually
	if "Tank" in name or "Walker" in name or "Plane" in name or "Tower" in name or "Base" in name or "CommandBay" in name:
		unit_attribute = "Mechanical"
	elif "Jellyfish" in name or "Beetle" in name or "Octopus" in name or "Squid" in name or "GreatBeastSpeaker" in name:
		unit_attribute = "Beast"

	if mesh:
		base_mesh_pos = mesh.position

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	var is_moving = false
		
	if is_player_controlled:
		# Movement (Player Controlled)
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			is_moving = true
			# Rotate to face direction
			var look_target = global_position + direction
			if global_position.distance_to(look_target) > 0.1:
				look_at(look_target, Vector3.UP)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	else:
		# Movement (AI Controlled)
		if current_target != null:
			var dist = global_position.distance_to(current_target.global_position)
			var effective_range = attack_range
			if "Base" in current_target.name:
				effective_range += 5.5
			elif "Tower" in current_target.name or "CommandBay" in current_target.name:
				effective_range += 2.5
			if dist > effective_range:
				var next_path_pos = current_target.global_position
				var new_velocity = global_position.direction_to(next_path_pos) * SPEED
				new_velocity.y = velocity.y
				velocity = new_velocity
				is_moving = true
				
				# Rotate to face direction
				var look_target = Vector3(next_path_pos.x, global_position.y, next_path_pos.z)
				if global_position.distance_to(look_target) > 0.1:
					look_at(look_target, Vector3.UP)
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
				
				# Face target while attacking
				var look_target = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
				if global_position.distance_to(look_target) > 0.1:
					look_at(look_target, Vector3.UP)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
				
	# Anti-stuck wall sliding
	if is_on_wall():
		var wall_normal = get_wall_normal()
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < SPEED * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * SPEED * 1.5
	
	move_and_slide()
	
	var ap = get_node_or_null("AnimationPlayer")
	if ap:
		if ap.current_animation == "attack" and ap.is_playing():
			pass
		elif is_moving:
			if ap.has_animation("walk") and ap.current_animation != "walk":
				ap.play("walk", 0.2, SPEED * 0.5)
		else:
			if ap.has_animation("idle") and ap.current_animation != "idle":
				ap.play("idle", 0.2)
	
	# Procedural Walk Animation (Bobbing)
	if mesh:
		if is_moving:
			walk_time += delta * SPEED * 2.0
			mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * 0.3
			mesh.rotation.z = sin(walk_time * 0.5) * 0.1
		else:
			walk_time = 0.0
			mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y, 10.0 * delta)
			mesh.rotation.z = lerp(mesh.rotation.z, 0.0, 10.0 * delta)
			
		# Recover from attack lunge
		mesh.position.z = lerp(mesh.position.z, base_mesh_pos.z, 15.0 * delta)
	
	# Auto-Attack (AI Controlled)
	if current_target == null or not is_instance_valid(current_target):
		find_new_target()
		
	if current_target != null:
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = attack_range
		if "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist <= effective_range:
			attack_timer -= delta
			if attack_timer <= 0:
				attack_timer = 1.0 / attack_speed
				var target_health = current_target.get_node_or_null("HealthComponent")
				if target_health:
					target_health.take_damage(attack_damage)
					var ap2 = get_node_or_null("AnimationPlayer")
					if ap2 and ap2.has_animation("attack"):
						ap2.play("attack", -1, attack_speed)
					# Attack lunge animation
					if mesh:
						mesh.position.z -= 0.5

func find_new_target():
	current_target = null
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
	var enemies = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if not node.is_in_group(my_team):
			enemies.append(node)
	
	var closest_dist = 99999.0
	for e in enemies:
		if is_instance_valid(e):
			var dist = global_position.distance_to(e.global_position)
			if dist < closest_dist:
				closest_dist = dist
				current_target = e
