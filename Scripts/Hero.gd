extends CharacterBody3D

@export var unit_attribute: String = "Organic"

@export var speed: float = 5.0
const ATTACK_RANGE = 2.0

@export var is_player_controlled: bool = false
@export var attack_damage: float = 25.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.0

var current_target: Node3D = null
var attack_timer: float = 0.0

var mesh: Node3D

var walk_time: float = 0.0
var base_mesh_pos: Vector3 = Vector3.ZERO

var humanoid_rig = null

func _get_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var root = (loop as SceneTree).root
		if root and root.has_node("GameState"):
			return root.get_node("GameState")
	return null

func _ready():
	mesh = get_node_or_null("MeshInstance3D")
	if not mesh: mesh = get_node_or_null("VisualPivot")
	if not mesh: mesh = get_node_or_null("Visuals")
	if not mesh: mesh = self # fallback
	add_to_group("Targetable")
		# Dynamically assign attribute based on name if not set manually
	if "Tank" in name or "Walker" in name or "Plane" in name or "Tower" in name or "Base" in name or "CommandBay" in name or "Mech" in name or "Leviathan" in name or "Spiker" in name:
		unit_attribute = "Mechanical"
	elif "Jellyfish" in name or "Beetle" in name or "Octopus" in name or "Squid" in name or "GreatBeastSpeaker" in name:
		unit_attribute = "Beast"

	if mesh:
		base_mesh_pos = mesh.position

	var rig_script = load("res://Scripts/HumanoidRig.gd")
	if rig_script:
		humanoid_rig = rig_script.new()
		humanoid_rig.name = "HumanoidRig"
		add_child(humanoid_rig)
		humanoid_rig.setup(self)



func _physics_process(delta):
	_apply_reach_synergy()

	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	if has_meta("stealth_revealed_timer"):
		var __s_timer = get_meta("stealth_revealed_timer", 0.0)
		if __s_timer > 0.0:
			set_meta("stealth_revealed_timer", max(0.0, __s_timer - delta))
		
	var is_moving = false
		
	if is_player_controlled:
		# Movement (Player Controlled)
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
		
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			is_moving = true
			# Rotate to face direction
			var look_target = global_position + direction
			if global_position.distance_to(look_target) > 0.1:
				look_at(look_target, Vector3.UP)
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	else:
		# Movement (AI Controlled)
		if is_instance_valid(current_target):
			var dist = global_position.distance_to(current_target.global_position)
			var effective_range = attack_range
			if "Base" in current_target.name:
				effective_range += 5.5
			elif "Tower" in current_target.name or "CommandBay" in current_target.name:
				effective_range += 2.5
			if dist > effective_range:
				var next_path_pos = current_target.global_position
				var desired_dir = (next_path_pos - global_position)
				desired_dir.y = 0
				if desired_dir.length_squared() > 0.001: desired_dir = desired_dir.normalized()
				
				# Obstacle whisker avoidance
				var space_state = get_world_3d().direct_space_state
				if space_state and desired_dir.length_squared() > 0.1:
					var r_start = global_position + Vector3(0, 0.5, 0)
					var r_end = r_start + desired_dir * 3.4
					var fwd_query = PhysicsRayQueryParameters3D.create(r_start, r_end, 1, [get_rid()])
					var fwd_hit = space_state.intersect_ray(fwd_query)
					if not fwd_hit.is_empty() and fwd_hit.collider is StaticBody3D:
						var l_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(45.0))
						var r_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(-45.0))
						var l_hit = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(r_start, r_start + l_dir * 3.2, 1, [get_rid()]))
						var r_hit = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(r_start, r_start + r_dir * 3.2, 1, [get_rid()]))
						if r_hit.is_empty() and not l_hit.is_empty():
							desired_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(-55.0))
						elif l_hit.is_empty() and not r_hit.is_empty():
							desired_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(55.0))

				var new_velocity = desired_dir * speed
				new_velocity.y = velocity.y
				velocity = new_velocity
				
				# Ground lane confinement
				if not can_wander_off_path():
					var gs = _get_game_state()
					if gs:
						var dist_to_lane = gs.get_distance_to_nearest_lane(global_position)
						if dist_to_lane > 10.5:
							var lane_pull = gs.get_vector_towards_nearest_lane(global_position)
							var pull_strength = clamp((dist_to_lane - 10.5) * 1.5, 0.6, 2.8)
							velocity += lane_pull * speed * pull_strength
				is_moving = true
				
				# Rotate to face direction
				var look_target = Vector3(next_path_pos.x, global_position.y, next_path_pos.z)
				if global_position.distance_to(look_target) > 0.1:
					look_at(look_target, Vector3.UP)
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
				
				# Face target while attacking
				var look_target = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
				if global_position.distance_to(look_target) > 0.1:
					look_at(look_target, Vector3.UP)
		else:
			current_target = null
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
				
	# Anti-stuck wall sliding
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.length() < 0.1: wall_normal = Vector3.UP
		wall_normal.y = 0
		if wall_normal.length_squared() > 0.01:
			wall_normal = wall_normal.normalized()
			var desired_fwd = velocity
			desired_fwd.y = 0
			if desired_fwd.length_squared() < 0.1 and is_instance_valid(current_target):
				desired_fwd = current_target.global_position - global_position
				desired_fwd.y = 0
			var slide_t = desired_fwd.slide(wall_normal).normalized()
			if slide_t.length_squared() < 0.1:
				slide_t = Vector3(-wall_normal.z, 0, wall_normal.x)
			velocity.x = slide_t.x * speed * 1.2
			velocity.z = slide_t.z * speed * 1.2
	
	move_and_slide()
	
	var ap = get_node_or_null("AnimationPlayer")
	if ap:
		if ap.current_animation == "attack" and ap.is_playing():
			pass
		elif is_moving:
			if ap.has_animation("walk") and ap.current_animation != "walk":
				ap.play("walk", 0.2, speed * 0.5)
		else:
			if ap.has_animation("idle") and ap.current_animation != "idle":
				ap.play("idle", 0.2)
	
	if humanoid_rig:
		var wounded = false
		var hc = get_node_or_null("HealthComponent")
		if hc and hc.has_method("is_critically_wounded"):
			wounded = hc.is_critically_wounded()
		humanoid_rig.animate(delta, is_moving, wounded, speed)
	elif mesh:
		if is_moving:
			walk_time += delta * speed * 2.0
			mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * 0.3
			mesh.rotation.z = sin(walk_time * 0.5) * 0.1
		else:
			walk_time = 0.0
			mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y, 10.0 * delta)
			mesh.rotation.z = lerp(mesh.rotation.z, 0.0, 10.0 * delta)
			
		# Recover from attack lunge
		mesh.position.z = lerp(mesh.position.z, base_mesh_pos.z, 15.0 * delta)

	
	# Auto-Attack (AI Controlled)
	if not "target_recheck_timer" in self:
		set_meta("target_recheck", 1.0)
	var __target_timer = get_meta("target_recheck") if has_meta("target_recheck") else 1.0
	__target_timer -= delta
	set_meta("target_recheck", __target_timer)
	
	var target_is_dead = false
	if is_instance_valid(current_target):
		var target_hc = current_target.get_node_or_null("HealthComponent")
		if (target_hc and target_hc.is_dead) or not current_target.is_in_group("Targetable"):
			target_is_dead = true
	else:
		current_target = null
			
	if current_target == null or target_is_dead or __target_timer <= 0.0:
		if __target_timer <= 0.0 or target_is_dead: set_meta("target_recheck", 1.0)
		find_new_target()
		
	if is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = attack_range
		if "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist <= effective_range:
			attack_timer -= delta
			if attack_timer <= 0:
				attack_timer = 1.0 / max(0.01, attack_speed)
				var target_health = current_target.get_node_or_null("HealthComponent")
				if target_health:
					set_meta("stealth_revealed_timer", 2.0)
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
	if my_team != "":
		for node in get_tree().get_nodes_in_group("Targetable"):
			if not node.is_in_group(my_team) and is_instance_valid(node) and node != self:
				if (node.is_in_group("NeutralCreature") or node.is_in_group("NeutralStructure")) and global_position.distance_to(node.global_position) > 7.5:
					continue
				var gs = _get_game_state()
				if not can_wander_off_path() and gs and gs.get_distance_to_nearest_lane(node.global_position) > 14.5 and global_position.distance_to(node.global_position) > 7.5:
					continue
				enemies.append(node)
	
	var closest_dist = 99999.0
	for e in enemies:
		if is_instance_valid(e):
			var target_hc = e.get_node_or_null("HealthComponent")
			if target_hc and target_hc.is_dead: continue
			var gs = _get_game_state()
			if gs and gs.is_unit_stealthed_from(e, self): continue
			var dist = global_position.distance_to(e.global_position)
			if dist < closest_dist:
				closest_dist = dist
				current_target = e

# --- Reach faction synergy: faster move/attack + bigger model when clustered with other Reach units ---
var _reach_base_speed: float = -1.0
var _reach_base_atk: float = -1.0

func _apply_reach_synergy():
	if not "Reach" in name:
		return
	if _reach_base_speed < 0.0:
		_reach_base_speed = get("speed") if "speed" in self else 0.0
		if "attack_speed" in self: _reach_base_atk = get("attack_speed")
		elif "attack_rate" in self: _reach_base_atk = get("attack_rate")
	var my_team := ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
	if my_team == "":
		return
	var reach_count := 0
	for node in get_tree().get_nodes_in_group(my_team):
		if node != self and node is Node3D and "Reach" in node.name and global_position.distance_to(node.global_position) < 6.0:
			reach_count += 1
	var synergy: float = min(reach_count, 5) * 0.15
	if "speed" in self: set("speed", _reach_base_speed * (1.0 + synergy))
	if _reach_base_atk > 0.0:
		if "attack_speed" in self: set("attack_speed", _reach_base_atk * (1.0 + synergy))
		elif "attack_rate" in self: set("attack_rate", _reach_base_atk / (1.0 + synergy))
	var r_mesh = get_node_or_null("MeshInstance3D")
	if not r_mesh: r_mesh = get_node_or_null("VisualPivot")
	if r_mesh: r_mesh.scale = r_mesh.scale.lerp(Vector3.ONE * (1.0 + synergy * 0.6), 0.1)

func can_wander_off_path() -> bool:
	return false
