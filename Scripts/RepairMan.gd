extends CharacterBody3D

@export var speed: float = 4.0
@export var repair_range: float = 3.0
@export var repair_amount: float = 40.0
@export var repair_rate: float = 1.0

var current_target: Node3D = null
var action_timer: float = 0.0

func _physics_process(delta):
	# Reach Synergy Inject
	var reach_count = 0
	if "Reach" in self.name:
		var my_team = ""
		for g in get_groups():
			if g.begins_with("Side"): my_team = g
		for node in get_tree().get_nodes_in_group(my_team):
			if node != self and "Reach" in node.name and global_position.distance_to(node.global_position) < 6.0:
				reach_count += 1
		var synergy = min(reach_count, 5) * 0.15
		speed = base_speed * (1.0 + synergy)
		if "attack_speed" in self: self.set("attack_speed", base_attack_val * (1.0 + synergy))
		elif "attack_rate" in self: self.set("attack_rate", base_attack_val / (1.0 + synergy))
		var r_mesh = get_node_or_null("MeshInstance3D")
		if not r_mesh: r_mesh = get_node_or_null("VisualPivot")
		if r_mesh: r_mesh.scale = r_mesh.scale.lerp(Vector3.ONE * (1.0 + (synergy * 0.6)), 0.1)

	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	if current_target == null or not is_instance_valid(current_target):
		find_new_target()
		
	var is_moving = false
	if current_target != null:
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = repair_range
		if current_target.get("unit_attribute") == "Mechanical":
			effective_range += 2.0
		elif "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist > effective_range:
			var next_path_pos = current_target.global_position
			var new_velocity = global_position.direction_to(next_path_pos) * speed
			new_velocity.y = velocity.y
			velocity = new_velocity
			is_moving = true
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			action_timer += delta
			if action_timer >= repair_rate:
				action_timer = 0.0
				
				var friendly_group = ""
				for g in get_groups():
					if g.begins_with("Side"): friendly_group = g
				
				# Are we repairing an ally or attacking an enemy?
				if current_target.is_in_group(friendly_group):
					var target_health = current_target.get_node_or_null("HealthComponent")
					if target_health:
						if target_health.current_health < target_health.max_health:
							target_health.heal(repair_amount)
						var ap = get_node_or_null("AnimationPlayer")
						if ap and ap.has_animation("repair"):
							ap.play("repair")
						
						if target_health.current_health >= target_health.max_health:
							current_target = null
				else:
					# Attack!
					var target_health = current_target.get_node_or_null("HealthComponent")
					if target_health:
						target_health.take_damage(10.0)

	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	var horiz_vel = Vector3(velocity.x, 0, velocity.z)
	var anim_mesh = get_node_or_null("MeshInstance3D")
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
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < speed * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * speed * 1.5
	
	move_and_slide()
	
	var ap = get_node_or_null("AnimationPlayer")
	if ap:
		if ap.current_animation == "repair" and ap.is_playing():
			pass
		elif is_moving:
			if ap.has_animation("walk") and ap.current_animation != "walk":
				ap.play("walk", 0.2, speed * 0.5)
		else:
			if ap.has_animation("idle") and ap.current_animation != "idle":
				ap.play("idle", 0.2)

func find_new_target():
	current_target = null
	
	# Priority 1: Find a damaged allied Tower or Base
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
		
	var allies = get_tree().get_nodes_in_group(my_team)
	var repair_target = null
	var closest_repair_dist = 99999.0
	
	for a in allies:
		if "Tower" in a.name or "Base" in a.name or "CommandBay" in a.name or a.get("unit_attribute") == "Mechanical":
			var hp = a.get_node_or_null("HealthComponent")
			if hp and hp.current_health < hp.max_health:
				var d = global_position.distance_to(a.global_position)
				if d < closest_repair_dist:
					closest_repair_dist = d
					repair_target = a
					
	if repair_target != null:
		current_target = repair_target
	else:
		# If no repairs are needed, act like a normal grunt and push the lane!
		var enemies = []
		for node in get_tree().get_nodes_in_group("Targetable"):
			if not node.is_in_group(my_team):
				enemies.append(node)
		var closest = 99999.0
		for e in enemies:
			if is_instance_valid(e):
				var d = global_position.distance_to(e.global_position)
				if d < closest:
					closest = d
					current_target = e


