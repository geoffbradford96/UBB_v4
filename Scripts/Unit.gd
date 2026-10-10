extends CharacterBody3D

@export var unit_attribute: String = "Organic"

var mesh: Node3D

@export var max_health: float = 100.0
@export var speed: float = 4.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.0

var current_target: Node3D = null
var attack_timer: float = 0.0

# Procedural Animation vars
var walk_time: float = 0.0
var base_mesh_pos: Vector3

var base_speed: float
var base_attack_speed: float

func _ready():
	mesh = get_node_or_null("MeshInstance3D")
	if not mesh: mesh = get_node_or_null("VisualPivot")
	if not mesh: mesh = get_node_or_null("Visuals")
	if not mesh: mesh = self # fallback
	base_speed = speed
	if "attack_speed" in self:
		base_attack_speed = self.get("attack_speed")
	add_to_group("Targetable")
		# Dynamically assign attribute based on name if not set manually
	if "Tank" in name or "Walker" in name or "Plane" in name or "Tower" in name or "Base" in name or "CommandBay" in name or "Mech" in name or "Leviathan" in name or "Spiker" in name:
		unit_attribute = "Mechanical"
	elif "Jellyfish" in name or "Beetle" in name or "Octopus" in name or "Squid" in name or "GreatBeastSpeaker" in name:
		unit_attribute = "Beast"

	base_mesh_pos = mesh.position
	var health = get_node_or_null("HealthComponent")
	if health:
		if max_health != 100.0:
			health.max_health = max_health
			health.current_health = max_health
		else:
			max_health = health.max_health

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	# Basic AI: Find nearest enemy, move to it, attack.
	if not "target_recheck_timer" in self:
		set_meta("target_recheck", 1.0)
	var __target_timer = get_meta("target_recheck") if has_meta("target_recheck") else 1.0
	__target_timer -= delta
	set_meta("target_recheck", __target_timer)
	
	var target_is_dead = false
	if current_target != null:
		var target_hc = current_target.get_node_or_null("HealthComponent")
		if (target_hc and target_hc.is_dead) or not current_target.is_in_group("Targetable"):
			target_is_dead = true
			
	if current_target == null or not is_instance_valid(current_target) or target_is_dead or __target_timer <= 0.0:
		if __target_timer <= 0.0 or target_is_dead: set_meta("target_recheck", 1.0)
		find_new_target()
		
	var is_moving = false
		
	if current_target != null:
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = attack_range
		if "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist > effective_range:
			# Move towards target
			var next_path_pos = current_target.global_position
			var new_velocity = global_position.direction_to(next_path_pos) * speed
			new_velocity.y = velocity.y # Preserve gravity
			velocity = new_velocity
			# --- Separation / Collision Avoidance ---
			var my_team = ""
			for g in get_groups():
				if g.begins_with("Side") or g == "Beast": my_team = g
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsShapeQueryParameters3D.new()
			var shape = SphereShape3D.new()
			shape.radius = 1.2
			query.shape = shape
			query.transform = global_transform
			var results = space_state.intersect_shape(query)
			var separation = Vector3.ZERO
			var reach_count = 0
			if unit_attribute == "Ethereal":
				results.clear()
			for res in results:
				var col = res.collider
				if col != self and col.is_in_group(my_team):
					if "Reach" in self.name and "Reach" in col.name: reach_count += 1
					if col.get("unit_attribute") == "Ethereal": continue

					var push = global_position - col.global_position
					push.y = 0
					var dist_to_col = push.length()
					if dist_to_col < 1.2 and dist_to_col > 0.01:
						separation += push.normalized() * (1.2 - dist_to_col)
			velocity += separation * speed * 2.0
			
			if "Reach" in self.name:
				var synergy = min(reach_count, 5) * 0.15 # Up to +75% speed and attack speed
				speed = base_speed * (1.0 + synergy)
				if "attack_speed" in self:
					self.set("attack_speed", base_attack_speed * (1.0 + synergy))
				var r_mesh = get_node_or_null("MeshInstance3D")
				if not r_mesh: r_mesh = get_node_or_null("VisualPivot")
				if r_mesh:
					var target_scale = 1.0 + (synergy * 0.6)
					r_mesh.scale = r_mesh.scale.lerp(Vector3(target_scale, target_scale, target_scale), 0.1)
			is_moving = true
			
			# Rotate to face movement direction
			var look_target = Vector3(next_path_pos.x, global_position.y, next_path_pos.z)
			if global_position.distance_to(look_target) > 0.1:
				look_at(look_target, Vector3.UP)
		else:
			# Stop and Attack
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			# Rotate to face target while attacking
			var look_target = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
			if global_position.distance_to(look_target) > 0.1:
				look_at(look_target, Vector3.UP)
				
			attack_timer -= delta
			if attack_timer <= 0:
				attack_timer = 1.0 / max(0.01, attack_speed)
				var target_health = current_target.get_node_or_null("HealthComponent")
				if target_health:
					if "SkyJellyfish" in self.name or "StoneOctopus" in self.name:
						var m_team = ""
						for g in get_groups():
							if g.begins_with("Side"): m_team = g
						for node in get_tree().get_nodes_in_group("Targetable"):
							if not node.is_in_group(m_team) and is_instance_valid(node):
								if self.global_position.distance_to(node.global_position) <= attack_range + 2.0:
									var hp = node.get_node_or_null("HealthComponent")
									if hp: hp.take_damage(attack_damage)
					else:
						target_health.take_damage(attack_damage)
						
					var ap_attack = get_node_or_null("AnimationPlayer")
					if ap_attack and ap_attack.has_animation("attack"):
						ap_attack.play("attack", -1, attack_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Anti-stuck wall sliding
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.length() < 0.1: wall_normal = Vector3.UP
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < speed * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * speed * 1.5
	
	move_and_slide()
	
	var ap = get_node_or_null("AnimationPlayer")
	if ap:
		if ap.current_animation == "attack" and ap.is_playing():
			pass # Let attack finish
		elif is_moving:
			if ap.has_animation("walk") and ap.current_animation != "walk":
				ap.play("walk", 0.2, speed * 0.5)
		else:
			if ap.has_animation("idle") and ap.current_animation != "idle":
				ap.play("idle", 0.2)
	elif mesh:
		_animate_mesh(delta, is_moving)

func _animate_mesh(delta: float, moving: bool):
	if moving:
		walk_time += delta * speed * 3.5
		mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * 0.15
		mesh.rotation.z = sin(walk_time) * 0.06
	else:
		mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y, 10.0 * delta)
		mesh.rotation.z = lerp(mesh.rotation.z, 0.0, 10.0 * delta)

func find_new_target():
	current_target = null
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
	var enemies = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if node != self and is_instance_valid(node):
			var hc = node.get_node_or_null("HealthComponent")
			if hc and hc.is_dead: continue
			if GameState.is_unit_stealthed_from(node, self): continue
			if my_team != "" and not node.is_in_group(my_team):
				enemies.append(node)
			elif my_team == "" and not node.is_in_group("Beast"):
				enemies.append(node)
	
	var closest_dist = 99999.0
	for e in enemies:
		if is_instance_valid(e):
			var dist = global_position.distance_to(e.global_position)
			if dist < closest_dist:
				closest_dist = dist
				current_target = e



