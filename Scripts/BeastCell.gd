extends "res://Scripts/Unit.gd"

func _ready():
	super._ready()
	var mesh_node = Node3D.new()
	add_child(mesh_node)
	self.mesh = mesh_node
	
	var blob = MeshInstance3D.new()
	blob.mesh = SphereMesh.new()
	blob.mesh.radius = 0.8
	blob.mesh.height = 1.2
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.1, 0.8)
	blob.material_override = mat
	blob.position.y = 0.6
	mesh_node.add_child(blob)
	
	var eye = MeshInstance3D.new()
	eye.mesh = SphereMesh.new()
	eye.mesh.radius = 0.3
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.0, 0.0)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.0, 0.0)
	eye.material_override = eye_mat
	eye.position = Vector3(0, 0.8, 0.7)
	mesh_node.add_child(eye)

func _physics_process(delta):
	super._physics_process(delta)
	if Vector2(velocity.x, velocity.z).length() > 0.1 and mesh:
		walk_time += delta * speed * 4.0
		var s = sin(walk_time)*0.2
		mesh.scale = Vector3(1.0 + s, 1.0 - s, 1.0 + s)
	elif mesh:
		mesh.scale = Vector3(1, 1, 1)

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
