extends CharacterBody3D

@export var speed: float = 5.0
@export var heal_range: float = 3.0
@export var heal_amount: float = 50.0
@export var heal_rate: float = 2.0 # Heals every 2 seconds

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_target: Node3D = null
var action_timer: float = 0.0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	# Find someone to heal!
	if current_target == null or not is_instance_valid(current_target):
		find_new_target()
		
	var is_moving = false
	if current_target != null:
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = heal_range
		if "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist > effective_range:
			# Move towards hurt ally
			var next_path_pos = current_target.global_position
			var new_velocity = global_position.direction_to(next_path_pos) * speed
			new_velocity.y = velocity.y
			velocity = new_velocity
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
						var ap = get_node_or_null("AnimationPlayer")
						if ap and ap.has_animation("heal"):
							ap.play("heal")
					
					# If they are fully healed (or already were), re-evaluate targets next frame
					if target_health.current_health >= target_health.max_health:
						current_target = null

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
			if health:
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



