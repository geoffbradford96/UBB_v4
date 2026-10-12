extends CharacterBody3D

@export var unit_attribute: String = "Organic"

@export var speed: float = 3.5
@export var attack_range: float = 18.0 
@export var damage: float = 15.0
@export var attack_rate: float = 1.2

var current_target: Node3D = null
var attack_timer: float = 0.0

var projectile_scene = preload("res://Scenes/Projectile.tscn")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	if has_meta("stealth_revealed_timer"):
		var __s_timer = get_meta("stealth_revealed_timer", 0.0)
		if __s_timer > 0.0:
			set_meta("stealth_revealed_timer", max(0.0, __s_timer - delta))
		
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
		if dist > attack_range:
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
				var dist_to_lane = GameState.get_distance_to_nearest_lane(global_position)
				if dist_to_lane > 10.5:
					var lane_pull = GameState.get_vector_towards_nearest_lane(global_position)
					var pull_strength = clamp((dist_to_lane - 10.5) * 1.5, 0.6, 2.8)
					velocity += lane_pull * speed * pull_strength
			is_moving = true
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			attack_timer += delta
			if attack_timer >= attack_rate:
				attack_timer = 0.0
				shoot()

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

func shoot():
	set_meta("stealth_revealed_timer", 2.0)
	if not is_instance_valid(current_target): return
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		var scene_root = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
		if scene_root:
			scene_root.add_child(proj)
			proj.global_position = global_position + Vector3(0, 1.0, 0)
			proj.target = current_target
			proj.set("damage", damage)
		
		# Make it look like a glowing yellow bullet
		var mesh = proj.get_node_or_null("MeshInstance3D")
		if mesh and mesh.mesh:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(1, 0.8, 0)
			mat.emission_enabled = true
			mat.emission = Color(1, 0.8, 0)
			mat.emission_energy_multiplier = 1.5
			mesh.set_surface_override_material(0, mat)

func find_new_target():
	current_target = null
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
	var enemies = []
	if my_team != "":
		for node in get_tree().get_nodes_in_group("Targetable"):
			if not node.is_in_group(my_team) and is_instance_valid(node) and node != self:
				enemies.append(node)
	var closest_dist = 99999.0
	for e in enemies:
		if is_instance_valid(e):
			var target_hc = e.get_node_or_null("HealthComponent")
			if target_hc and target_hc.is_dead: continue
			if GameState.is_unit_stealthed_from(e, self): continue
			var d = global_position.distance_to(e.global_position)
			if d < closest_dist:
				closest_dist = d
				current_target = e

func can_wander_off_path() -> bool:
	return false



