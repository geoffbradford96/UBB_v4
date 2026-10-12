extends CharacterBody3D

@export var unit_attribute: String = "Organic"

@export var speed: float = 5.0
@export var heal_range: float = 3.0
@export var heal_amount: float = 50.0
@export var heal_rate: float = 2.0 # Heals every 2 seconds


var current_target: Node3D = null
var action_timer: float = 0.0

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
	add_to_group("Targetable")
	var rig_script = load("res://Scripts/HumanoidRig.gd")
	if rig_script:
		humanoid_rig = rig_script.new()
		humanoid_rig.name = "HumanoidRig"
		add_child(humanoid_rig)
		humanoid_rig.setup(self)



func _physics_process(delta):
	_apply_reach_synergy()

	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	# Find someone to heal!
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
		
	var is_moving = false
	if is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = heal_range
		if "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist > effective_range:
			# Move towards hurt ally
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
		else:
			# Stop and Heal
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			action_timer += delta
			if action_timer >= heal_rate:
				action_timer = 0.0
				var target_health = current_target.get_node_or_null("HealthComponent")
				if target_health:
					# Only pop a heal if they actually need it!
					if target_health.current_health < target_health.max_health:
						print("Medic heals ", current_target.name, " for ", heal_amount)
						target_health.heal(heal_amount)
						var ap_action = get_node_or_null("AnimationPlayer")
						if ap_action and ap_action.has_animation("heal"):
							ap_action.play("heal")
					
					# If they are fully healed (or already were), re-evaluate targets next frame
					if target_health.current_health >= target_health.max_health:
						current_target = null

	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	var horiz_vel = Vector3(velocity.x, 0, velocity.z)
	var anim_mesh = get_node_or_null("MeshInstance3D")
	if not anim_mesh: anim_mesh = get_node_or_null("VisualPivot")
	if horiz_vel.length() > 0.1:
		var look_target = global_position + horiz_vel
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target, Vector3.UP)
		if anim_mesh:
			var t = Time.get_ticks_msec() / 1000.0 * speed * 2.0
			anim_mesh.rotation.z = sin(t) * 0.1
			anim_mesh.rotation.x = cos(t) * 0.1
	else:
		if current_target != null and is_instance_valid(current_target):
			var look_target = current_target.global_position
			look_target.y = global_position.y
			if global_position.distance_to(look_target) > 0.1:
				look_at(look_target, Vector3.UP)
		if anim_mesh:
			anim_mesh.rotation.z = lerp(anim_mesh.rotation.z, 0.0, 10.0 * delta)
			anim_mesh.rotation.x = lerp(anim_mesh.rotation.x, 0.0, 10.0 * delta)
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
	
	if humanoid_rig:
		var wounded = false
		var hc = get_node_or_null("HealthComponent")
		if hc and hc.has_method("is_critically_wounded"):
			wounded = hc.is_critically_wounded()
		humanoid_rig.animate(delta, is_moving, wounded, speed)
	else:
		var ap = get_node_or_null("AnimationPlayer")
		if ap:
			if ap.current_animation == "heal" and ap.is_playing():
				pass
			elif is_moving:
				if ap.has_animation("walk") and ap.current_animation != "walk":
					ap.play("walk", 0.2, speed * 0.5)
			else:
				if ap.has_animation("idle") and ap.current_animation != "idle":
					ap.play("idle", 0.2)


func find_new_target():
	current_target = null
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
	var allies = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if node.is_in_group(my_team) and node != self:
			allies.append(node)
	var closest_dist = 99999.0
	var healthy_fallback = null
	var closest_healthy_dist = 99999.0
	
	for a in allies:
		if is_instance_valid(a) and a != self:
			var health = a.get_node_or_null("HealthComponent")
			if health and not health.is_dead:
				var d = global_position.distance_to(a.global_position)
				# Priority 1: Target injured allies
				if health.current_health < health.max_health:
					if d < closest_dist:
						closest_dist = d
						current_target = a
				# Priority 2: Keep track of healthy allies to follow just in case
				elif current_target == null and d < closest_healthy_dist:
					closest_healthy_dist = d
					healthy_fallback = a
					
	# If no one is hurt, follow the closest healthy ally so we stay with the army!
	if current_target == null and healthy_fallback != null:
		current_target = healthy_fallback

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
