extends "res://Scripts/Unit.gd"

var spike_nodes: Array = []

func _ready():
	unit_attribute = "Organic"
	add_to_group("Targetable")
	add_to_group("Beast")
	
	speed = 9.0
	attack_range = 1.8
	attack_damage = 28.0
	attack_speed = 1.1
	max_health = 130.0
	
	super._ready()
	
	# Procedural Model: Small Spiked Melee Cell (Antibody)
	var mesh_node = Node3D.new()
	add_child(mesh_node)
	self.mesh = mesh_node
	
	# 1. Central Bio-Nucleus Core
	var blob = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.65
	sm.height = 0.95
	blob.mesh = sm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.05, 0.3)
	mat.roughness = 0.45
	blob.material_override = mat
	blob.position.y = 0.5
	mesh_node.add_child(blob)
	
	# 2. Glowing Predatory Core Eye
	var eye = MeshInstance3D.new()
	var em = SphereMesh.new()
	em.radius = 0.25
	em.height = 0.4
	eye.mesh = em
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.05, 0.05)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.05, 0.05)
	eye_mat.emission_energy_multiplier = 3.5
	eye.material_override = eye_mat
	eye.position = Vector3(0, 0.52, 0.58)
	mesh_node.add_child(eye)
	
	# 3. Radiating Chitin / Bone Spikes (Antibody Defense Spines)
	var spike_mat = StandardMaterial3D.new()
	spike_mat.albedo_color = Color(0.9, 0.86, 0.76)
	spike_mat.metallic = 0.2
	spike_mat.roughness = 0.5
	
	var spike_holder = Node3D.new()
	spike_holder.position.y = 0.5
	mesh_node.add_child(spike_holder)
	mesh_node.set_meta("spike_holder", spike_holder)
	
	# 6 Equatorial Radial Spikes
	for i in range(6):
		var sp = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.0
		cyl.bottom_radius = 0.12
		cyl.height = 0.95
		sp.mesh = cyl
		sp.material_override = spike_mat
		var a = i * (PI / 3.0)
		sp.position = Vector3(cos(a) * 0.5, 0, sin(a) * 0.5)
		sp.rotation.y = -a + PI/2.0
		sp.rotation.z = PI/2.0
		spike_holder.add_child(sp)
		spike_nodes.append(sp)
		
	# 2 Top Diagonal Spines
	for side in [-1, 1]:
		var sp = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.0
		cyl.bottom_radius = 0.11
		cyl.height = 0.85
		sp.mesh = cyl
		sp.material_override = spike_mat
		sp.position = Vector3(side * 0.25, 0.38, -0.2)
		sp.rotation_degrees = Vector3(-35, 0, side * 30)
		spike_holder.add_child(sp)
		spike_nodes.append(sp)
		
	# 2 Forward Mandible Stabs
	for side in [-1, 1]:
		var sp = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.0
		cyl.bottom_radius = 0.1
		cyl.height = 0.75
		sp.mesh = cyl
		sp.material_override = spike_mat
		sp.position = Vector3(side * 0.32, -0.05, 0.45)
		sp.rotation_degrees = Vector3(80, side * 15, 0)
		spike_holder.add_child(sp)
		spike_nodes.append(sp)
		
	base_mesh_pos = mesh_node.position

func _animate_mesh(delta: float, moving: bool):
	if moving and mesh:
		walk_time += delta * speed * 3.8
		var s = sin(walk_time) * 0.18
		mesh.scale = Vector3(1.0 + s, 1.0 - s * 0.7, 1.0 + s)
		mesh.position.y = base_mesh_pos.y + abs(sin(walk_time * 0.5)) * 0.22
	elif mesh:
		mesh.scale = mesh.scale.lerp(Vector3.ONE, 10.0 * delta)
		mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y, 10.0 * delta)
		
	# Spike breathing / flare
	if mesh and mesh.has_meta("spike_holder"):
		var holder = mesh.get_meta("spike_holder")
		if is_instance_valid(holder):
			var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.08
			holder.scale = holder.scale.lerp(Vector3(pulse, pulse, pulse), 8.0 * delta)

func _physics_process(delta):
	# Hook into attack to trigger aggressive spike lunge animation
	if current_target != null and is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		if dist <= attack_range + 0.5 and attack_timer <= delta * 2.0:
			if mesh and mesh.has_meta("spike_holder"):
				var holder = mesh.get_meta("spike_holder")
				if is_instance_valid(holder):
					var tw = create_tween()
					tw.tween_property(holder, "scale", Vector3(1.45, 1.45, 1.45), 0.08)
					tw.tween_property(holder, "scale", Vector3(1.0, 1.0, 1.0), 0.2)
					
	super._physics_process(delta)

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
