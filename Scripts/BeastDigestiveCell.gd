extends "res://Scripts/Unit.gd"

var projectile_scene = preload("res://Scenes/Projectile.tscn")
var mesh_node: Node3D = null

func _ready():
	unit_attribute = "Organic"
	add_to_group("Targetable")
	add_to_group("Beast")
	
	speed = 6.0
	attack_range = 14.0
	attack_damage = 22.0
	attack_speed = 0.65
	
	super._ready()
	
	# Procedural model for Digestive Acid Cell
	mesh_node = Node3D.new()
	add_child(mesh_node)
	self.mesh = mesh_node
	
	# 1. Main Bloated Acid Vesicle Sac (translucent toxic membrane)
	var vesicle = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.85
	sm.height = 1.15
	vesicle.mesh = sm
	var v_mat = StandardMaterial3D.new()
	v_mat.albedo_color = Color(0.2, 0.55, 0.12, 0.88)
	v_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	v_mat.roughness = 0.25
	vesicle.material_override = v_mat
	vesicle.position.y = 0.65
	mesh_node.add_child(vesicle)
	
	# 2. Glowing Internal Caustic Core
	var core = MeshInstance3D.new()
	var cm = SphereMesh.new()
	cm.radius = 0.52
	cm.height = 0.72
	core.mesh = cm
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.45, 1.0, 0.1)
	c_mat.emission_enabled = true
	c_mat.emission = Color(0.45, 1.0, 0.1)
	c_mat.emission_energy_multiplier = 3.5
	core.material_override = c_mat
	core.position.y = 0.65
	mesh_node.add_child(core)
	mesh_node.set_meta("acid_core", core)
	
	# 3. External Acid Pores / Blisters
	var blister_mat = StandardMaterial3D.new()
	blister_mat.albedo_color = Color(0.7, 0.95, 0.15)
	blister_mat.emission_enabled = true
	blister_mat.emission = Color(0.6, 0.9, 0.1)
	blister_mat.emission_energy_multiplier = 1.8
	
	for i in range(4):
		var bl = MeshInstance3D.new()
		var bm = SphereMesh.new()
		bm.radius = 0.22 + (i % 2) * 0.05
		bm.height = bm.radius * 2.0
		bl.mesh = bm
		bl.material_override = blister_mat
		var a = i * (PI / 2.0) + 0.35
		bl.position = Vector3(cos(a) * 0.7, 0.75 + (i % 2) * 0.15, sin(a) * 0.7)
		mesh_node.add_child(bl)
		
	# 4. Spitting Siphon Nozzle (Front facing)
	var siphon = MeshInstance3D.new()
	var nozzle = CylinderMesh.new()
	nozzle.top_radius = 0.14
	nozzle.bottom_radius = 0.24
	nozzle.height = 0.45
	siphon.mesh = nozzle
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.12, 0.28, 0.08)
	s_mat.roughness = 0.7
	siphon.material_override = s_mat
	siphon.rotation_degrees.x = 90
	siphon.position = Vector3(0, 0.65, 0.8)
	mesh_node.add_child(siphon)
	
	base_mesh_pos = mesh_node.position

func _animate_mesh(delta: float, moving: bool):
	var t = Time.get_ticks_msec() * 0.005
	if moving and mesh:
		walk_time += delta * speed * 3.0
		var s = sin(walk_time) * 0.14
		mesh.scale = Vector3(1.0 + s, 1.0 - s * 0.8, 1.0 + s)
		mesh.position.y = base_mesh_pos.y + abs(sin(walk_time * 0.6)) * 0.2
	elif mesh:
		mesh.scale = mesh.scale.lerp(Vector3.ONE, 8.0 * delta)
		mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y + sin(t * 2.5) * 0.08, 6.0 * delta)
		
	# Pulsing acid core illumination
	if mesh_node and mesh_node.has_meta("acid_core"):
		var core = mesh_node.get_meta("acid_core")
		if is_instance_valid(core) and core.material_override:
			core.material_override.emission_energy_multiplier = 3.0 + sin(t * 4.0) * 1.5

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	if not has_meta("target_recheck"):
		set_meta("target_recheck", 1.0)
	var __target_timer = get_meta("target_recheck")
	__target_timer -= delta
	set_meta("target_recheck", __target_timer)
	
	if current_target == null or not is_instance_valid(current_target) or __target_timer <= 0.0:
		if __target_timer <= 0.0: set_meta("target_recheck", 1.0)
		find_new_target()
		
	var is_moving = false
	if current_target != null:
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = attack_range
		if "Base" in current_target.name: effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name: effective_range += 2.5
		
		if dist > effective_range:
			# Move towards target
			var next_path_pos = current_target.global_position
			var new_velocity = global_position.direction_to(next_path_pos) * speed
			new_velocity.y = velocity.y
			velocity = new_velocity
			is_moving = true
			
			var look_target = Vector3(next_path_pos.x, global_position.y, next_path_pos.z)
			if global_position.distance_to(look_target) > 0.1:
				look_at(look_target, Vector3.UP)
		else:
			# Stop and Attack with ranged acid spit
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
			var look_target = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
			if global_position.distance_to(look_target) > 0.1:
				look_at(look_target, Vector3.UP)
				
			attack_timer -= delta
			if attack_timer <= 0.0:
				attack_timer = 1.0 / max(0.01, attack_speed)
				shoot_acid_glob()
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	# Wall slide anti-stuck
	if is_on_wall():
		var wall_normal = get_wall_normal()
		if wall_normal.length() < 0.1: wall_normal = Vector3.UP
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < speed * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * speed * 1.5
			
	move_and_slide()
	_animate_mesh(delta, is_moving)

func shoot_acid_glob():
	if current_target == null or not is_instance_valid(current_target): return
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		var spawn_pos = global_position + Vector3(0, 0.65, 0)
		proj.global_position = spawn_pos
		proj.target = current_target
		proj.set("speed", 18.0)
		
		# Calculate bonus damage against Organic units!
		var dmg = attack_damage
		var target_attr = ""
		if "unit_attribute" in current_target:
			target_attr = current_target.unit_attribute
		elif current_target.has_method("get"):
			var a = current_target.get("unit_attribute")
			if a != null: target_attr = str(a)
		
		var is_organic = target_attr == "Organic" or target_attr == "Beast" or "Organic" in current_target.get_groups()
		if is_organic:
			dmg *= 2.2 # 120% bonus damage melts organic flesh!
			
		proj.set("damage", dmg)
		proj.set("is_poisonous", true) # Burns with caustic digestive acid over time!
		
		# Style projectile as caustic bubbling acid glob
		var p_mesh = proj.get_node_or_null("MeshInstance3D")
		if p_mesh and p_mesh.mesh:
			var mat = StandardMaterial3D.new()
			var acid_color = Color(0.3, 1.0, 0.08)
			mat.albedo_color = acid_color
			mat.emission_enabled = true
			mat.emission = acid_color
			mat.emission_energy_multiplier = 4.0
			p_mesh.set_surface_override_material(0, mat)
			
		# Spitting convulsion animation
		if mesh:
			var tw = create_tween()
			tw.tween_property(mesh, "scale", Vector3(1.25, 0.75, 0.8), 0.08)
			tw.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func find_new_target():
	current_target = null
	var enemies = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if not node.is_in_group("Beast") and is_instance_valid(node) and node != self:
			enemies.append(node)
	var closest = 99999.0
	for e in enemies:
		if is_instance_valid(e):
			var d = global_position.distance_to(e.global_position)
			if d < closest:
				closest = d
				current_target = e
