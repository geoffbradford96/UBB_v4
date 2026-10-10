extends CharacterBody3D

@export var unit_attribute: String = "Organic"

@export var speed: float = 6.0
@export var attack_range: float = 2.0
@export var damage: float = 15.0
@export var attack_rate: float = 0.5 # attacks fast!

var mesh: Node3D

var current_target: Node3D = null
var attack_timer: float = 0.0
var is_invisible: bool = true

var base_speed: float
var base_attack_speed: float

func _ready():
	add_to_group("Targetable")
	mesh = get_node_or_null("MeshInstance3D")
	if not mesh: mesh = get_node_or_null("VisualPivot")
	if not mesh: mesh = get_node_or_null("Visuals")
	if not mesh: mesh = self # fallback
	base_speed = speed
	if "attack_speed" in self:
		base_attack_speed = self.get("attack_speed")
	# Make Assassin partially transparent
	if mesh is MeshInstance3D and mesh.mesh:
		var active_mat = mesh.material_override
		if not active_mat and mesh.mesh.get_surface_count() > 0:
			active_mat = mesh.mesh.surface_get_material(0)
		if active_mat:
			var mat = active_mat.duplicate()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.3
			mesh.material_override = mat

func _physics_process(delta):
	_apply_reach_synergy()

	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
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
			# Move
			var next_path_pos = current_target.global_position
			var new_velocity = global_position.direction_to(next_path_pos) * speed
			new_velocity.y = velocity.y
			velocity = new_velocity
			is_moving = true
		else:
			# Stop and Attack
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			attack_timer += delta
			if attack_timer >= attack_rate:
				attack_timer = 0.0
				print("Assassin slices ", current_target.name, "!")
				var target_health = current_target.get_node_or_null("HealthComponent")
				if target_health:
					target_health.take_damage(damage)
					var ap_action = get_node_or_null("AnimationPlayer")
					if ap_action and ap_action.has_animation("attack"):
						ap_action.play("attack")

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
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < speed * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * speed * 1.5
	
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

func find_new_target():
	current_target = null
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
	var enemies = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if not node.is_in_group(my_team):
			enemies.append(node)
	var closest_off_lane_dist = 99999.0
	var closest_normal_dist = 99999.0
	var off_lane_target = null
	var normal_target = null
	
	for e in enemies:
		if is_instance_valid(e):
			var target_hc = e.get_node_or_null("HealthComponent")
			if target_hc and target_hc.is_dead: continue
			if GameState.is_unit_stealthed_from(e, self): continue
			var d = global_position.distance_to(e.global_position)
			# Is the enemy a high-value backline target or off-lane flanker?
			var is_priority = "Sniper" in e.name or "Ranged" in e.name or "Hunter" in e.name or "CommandBay" in e.name or abs(e.global_position.x) > 18
			if is_priority:
				if d < closest_off_lane_dist:
					closest_off_lane_dist = d
					off_lane_target = e
			else:
				if d < closest_normal_dist:
					closest_normal_dist = d
					normal_target = e
					
	# Prioritize off-lane target! If none, just go forward.
	if off_lane_target != null:
		current_target = off_lane_target
	elif normal_target != null:
		current_target = normal_target

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
