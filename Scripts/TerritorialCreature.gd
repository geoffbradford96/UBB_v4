extends CharacterBody3D
class_name TerritorialCreature

@export var creature_type: String = "Scorpion" # "Scorpion" or "SwarmAnt"
@export var nest_radius: float = 8.5
@export var leash_radius: float = 11.5
@export var home_position: Vector3 = Vector3.ZERO

@export var max_health: float = 120.0
@export var speed: float = 4.8
@export var attack_damage: float = 14.0
@export var attack_range: float = 1.8
@export var attack_speed: float = 1.2

var current_target: Node3D = null
var attack_timer: float = 0.0
var recheck_timer: float = 0.0
var idle_patrol_timer: float = 0.0
var idle_patrol_offset: Vector3 = Vector3.ZERO
var visual_mesh: Node3D = null
var anim_time: float = 0.0

func _ready():
	add_to_group("Targetable")
	add_to_group("NeutralCreature")
	if creature_type == "Scorpion":
		add_to_group("Scorpion")
	else:
		add_to_group("SwarmAnt")
		
	# Setup HealthComponent
	var hc = get_node_or_null("HealthComponent")
	if not hc:
		hc = HealthComponent.new()
		hc.name = "HealthComponent"
		add_child(hc)
	hc.set_max_health(max_health)
	if not hc.died.is_connected(_on_died):
		hc.died.connect(_on_died)
		
	if home_position == Vector3.ZERO:
		home_position = global_position
		
	recheck_timer = randf_range(0.1, 0.4)
	idle_patrol_timer = randf_range(0.5, 3.0)
	
	_setup_collision()
	_setup_model()

func configure_creature(type: String, home: Vector3):
	creature_type = type
	home_position = home
	if creature_type == "Scorpion":
		max_health = 120.0
		speed = 4.8
		attack_damage = 14.0
		attack_range = 1.8
		attack_speed = 1.2
		nest_radius = 8.5
		leash_radius = 12.0
	else: # SwarmAnt - "little stats", fast swarmers
		max_health = 32.0
		speed = 5.6
		attack_damage = 3.5
		attack_range = 1.2
		attack_speed = 1.6
		nest_radius = 7.5
		leash_radius = 10.5
		
	var hc = get_node_or_null("HealthComponent")
	if hc:
		hc.set_max_health(max_health)
	if visual_mesh:
		for c in visual_mesh.get_children(): c.queue_free()
		if creature_type == "Scorpion":
			_build_scorpion_mesh()
		else:
			_build_ant_mesh()

func _setup_collision():
	var col = get_node_or_null("CollisionShape3D")
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var shape = SphereShape3D.new()
		shape.radius = 0.6 if creature_type == "Scorpion" else 0.3
		col.shape = shape
		col.position.y = 0.3 if creature_type == "Scorpion" else 0.15
		add_child(col)

func _setup_model():
	visual_mesh = Node3D.new()
	visual_mesh.name = "CreatureVisuals"
	add_child(visual_mesh)
	
	if creature_type == "Scorpion":
		_build_scorpion_mesh()
	else:
		_build_ant_mesh()

func _build_scorpion_mesh():
	var chitin_mat = StandardMaterial3D.new()
	chitin_mat.albedo_color = Color(0.38, 0.22, 0.10) # Dark desert amber chitin
	chitin_mat.roughness = 0.65
	
	var accent_mat = StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.24, 0.14, 0.06)
	accent_mat.roughness = 0.5
	
	var stinger_mat = StandardMaterial3D.new()
	stinger_mat.albedo_color = Color(0.85, 0.25, 0.12) # Venomous red-orange stinger
	stinger_mat.emission_enabled = true
	stinger_mat.emission = Color(0.7, 0.2, 0.05)
	stinger_mat.emission_energy_multiplier = 0.8
	
	# Thorax / Body
	var body_m = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(0.7, 0.25, 1.0)
	body_m.mesh = body_box
	body_m.material_override = chitin_mat
	body_m.position.y = 0.25
	visual_mesh.add_child(body_m)
	
	# Head
	var head_m = MeshInstance3D.new()
	var head_box = BoxMesh.new()
	head_box.size = Vector3(0.5, 0.2, 0.4)
	head_m.mesh = head_box
	head_m.material_override = accent_mat
	head_m.position = Vector3(0, 0.24, -0.6)
	visual_mesh.add_child(head_m)
	
	# Pincers Left and Right
	for side in [-1.0, 1.0]:
		var claw_arm = MeshInstance3D.new()
		var arm_box = BoxMesh.new()
		arm_box.size = Vector3(0.12, 0.12, 0.4)
		claw_arm.mesh = arm_box
		claw_arm.material_override = chitin_mat
		claw_arm.position = Vector3(side * 0.45, 0.22, -0.7)
		claw_arm.rotation.y = side * 0.4
		visual_mesh.add_child(claw_arm)
		
		var pincer = MeshInstance3D.new()
		var pincer_box = BoxMesh.new()
		pincer_box.size = Vector3(0.2, 0.12, 0.3)
		pincer.mesh = pincer_box
		pincer.material_override = accent_mat
		pincer.position = Vector3(side * 0.6, 0.22, -0.95)
		visual_mesh.add_child(pincer)
		
	# Arched Stinger Tail (4 segments curved up and forward)
	var tail_segs = [
		Vector3(0, 0.35, 0.55),
		Vector3(0, 0.65, 0.70),
		Vector3(0, 0.95, 0.50),
		Vector3(0, 1.05, 0.20)
	]
	for pos in tail_segs:
		var seg = MeshInstance3D.new()
		var seg_box = BoxMesh.new()
		seg_box.size = Vector3(0.22, 0.22, 0.25)
		seg.mesh = seg_box
		seg.material_override = chitin_mat
		seg.position = pos
		visual_mesh.add_child(seg)
		
	# Venom Stinger Bulb & Spike
	var stinger = MeshInstance3D.new()
	var stinger_cone = CylinderMesh.new()
	stinger_cone.top_radius = 0.02
	stinger_cone.bottom_radius = 0.12
	stinger_cone.height = 0.3
	stinger.mesh = stinger_cone
	stinger.material_override = stinger_mat
	stinger.position = Vector3(0, 1.05, -0.05)
	stinger.rotation.x = -1.2 # Curved pointing forward
	visual_mesh.add_child(stinger)

func _build_ant_mesh():
	var ant_mat = StandardMaterial3D.new()
	ant_mat.albedo_color = Color(0.22, 0.12, 0.08) # Reddish-black desert swarm ant
	ant_mat.roughness = 0.7
	
	# Scale whole visual small
	visual_mesh.scale = Vector3(0.55, 0.55, 0.55)
	
	# Head
	var head = MeshInstance3D.new()
	var head_sph = SphereMesh.new()
	head_sph.radius = 0.18
	head_sph.height = 0.32
	head.mesh = head_sph
	head.material_override = ant_mat
	head.position = Vector3(0, 0.25, -0.38)
	visual_mesh.add_child(head)
	
	# Thorax
	var thorax = MeshInstance3D.new()
	var th_sph = SphereMesh.new()
	th_sph.radius = 0.14
	th_sph.height = 0.28
	thorax.mesh = th_sph
	thorax.material_override = ant_mat
	thorax.position = Vector3(0, 0.24, 0.0)
	visual_mesh.add_child(thorax)
	
	# Abdomen / Gaster
	var abdomen = MeshInstance3D.new()
	var ab_sph = SphereMesh.new()
	ab_sph.radius = 0.22
	ab_sph.height = 0.42
	abdomen.mesh = ab_sph
	abdomen.material_override = ant_mat
	abdomen.position = Vector3(0, 0.28, 0.42)
	visual_mesh.add_child(abdomen)
	
	# Tiny mandibles
	for side in [-1.0, 1.0]:
		var mand = MeshInstance3D.new()
		var mand_box = BoxMesh.new()
		mand_box.size = Vector3(0.06, 0.04, 0.14)
		mand.mesh = mand_box
		mand.material_override = ant_mat
		mand.position = Vector3(side * 0.1, 0.20, -0.54)
		mand.rotation.y = side * -0.3
		visual_mesh.add_child(mand)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	if has_meta("stealth_revealed_timer"):
		var __s_timer = get_meta("stealth_revealed_timer", 0.0)
		if __s_timer > 0.0:
			set_meta("stealth_revealed_timer", max(0.0, __s_timer - delta))
		
	# Retargeting check
	recheck_timer -= delta
	if recheck_timer <= 0.0:
		recheck_timer = randf_range(0.25, 0.45)
		_evaluate_targeting()
		
	var is_moving = false
	
	if current_target != null and is_instance_valid(current_target):
		var dist_to_target = global_position.distance_to(current_target.global_position)
		var dist_from_home = home_position.distance_to(current_target.global_position)
		
		# Leash break check
		if dist_from_home > leash_radius:
			current_target = null
		elif dist_to_target > attack_range:
			# Chase target
			var move_dir = (current_target.global_position - global_position).normalized()
			velocity.x = move_dir.x * speed
			velocity.z = move_dir.z * speed
			is_moving = true
			
			var look_pos = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
			if global_position.distance_to(look_pos) > 0.1:
				look_at(look_pos, Vector3.UP)
		else:
			# Attack target
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			var look_pos = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
			if global_position.distance_to(look_pos) > 0.1:
				look_at(look_pos, Vector3.UP)
				
			attack_timer -= delta
			if attack_timer <= 0.0:
				attack_timer = 1.0 / max(0.01, attack_speed)
				var th = current_target.get_node_or_null("HealthComponent")
				if th and not th.is_dead:
					set_meta("stealth_revealed_timer", 2.0)
					th.take_damage(attack_damage)
					# Visual attack lunge
					if visual_mesh:
						visual_mesh.position.z -= 0.2
	else:
		# Return to home nest or idle wander
		var dist_to_home = global_position.distance_to(home_position)
		if dist_to_home > 2.2:
			var home_dir = (home_position + idle_patrol_offset - global_position).normalized()
			velocity.x = home_dir.x * (speed * 0.7)
			velocity.z = home_dir.z * (speed * 0.7)
			is_moving = true
			
			var look_pos = global_position + Vector3(home_dir.x, 0, home_dir.z)
			if global_position.distance_to(look_pos) > 0.1:
				look_at(look_pos, Vector3.UP)
		else:
			# Idle patrol near nest
			idle_patrol_timer -= delta
			if idle_patrol_timer <= 0.0:
				idle_patrol_timer = randf_range(2.0, 5.0)
				var angle = randf() * TAU
				var r = randf_range(0.5, nest_radius * 0.5)
				idle_patrol_offset = Vector3(cos(angle) * r, 0, sin(angle) * r)
				
			var patrol_target = home_position + idle_patrol_offset
			if global_position.distance_to(patrol_target) > 0.5:
				var p_dir = (patrol_target - global_position).normalized()
				velocity.x = p_dir.x * (speed * 0.35)
				velocity.z = p_dir.z * (speed * 0.35)
				is_moving = true
				
				var look_pos = global_position + Vector3(p_dir.x, 0, p_dir.z)
				if global_position.distance_to(look_pos) > 0.1:
					look_at(look_pos, Vector3.UP)
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
				
	# Anti-stuck wall sliding against rocks and dunes
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.length() < 0.1: wall_normal = Vector3.UP
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < speed * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * speed * 1.5
				
	move_and_slide()
	
	# Procedural walk wobble
	if visual_mesh:
		if is_moving:
			anim_time += delta * speed * 4.0
			visual_mesh.rotation.y = sin(anim_time) * 0.12
			visual_mesh.position.y = abs(sin(anim_time * 2.0)) * 0.05
			visual_mesh.position.z = lerp(visual_mesh.position.z, 0.0, 10.0 * delta)
		else:
			visual_mesh.rotation.y = lerp(visual_mesh.rotation.y, 0.0, 10.0 * delta)
			visual_mesh.position.y = lerp(visual_mesh.position.y, 0.0, 10.0 * delta)
			visual_mesh.position.z = lerp(visual_mesh.position.z, 0.0, 10.0 * delta)

func _evaluate_targeting():
	if current_target != null:
		if not is_instance_valid(current_target):
			current_target = null
		else:
			var hc = current_target.get_node_or_null("HealthComponent")
			if hc and hc.is_dead:
				current_target = null
				
	if current_target == null:
		var closest_dist = nest_radius
		var best_target = null
		
		var my_group = "Scorpion" if creature_type == "Scorpion" else "SwarmAnt"
		for node in get_tree().get_nodes_in_group("Targetable"):
			if node == self or not is_instance_valid(node): continue
			if node.is_in_group(my_group): continue # Don't fight fellow nestmates
			
			var hc = node.get_node_or_null("HealthComponent")
			if hc and hc.is_dead: continue
			
			# Check stealth in grass
			if GameState.is_unit_stealthed_from(node, self):
				continue
				
			var dist_from_nest = home_position.distance_to(node.global_position)
			if dist_from_nest <= nest_radius and dist_from_nest < closest_dist:
				closest_dist = dist_from_nest
				best_target = node
				
		current_target = best_target

func _on_died():
	set_physics_process(false)
