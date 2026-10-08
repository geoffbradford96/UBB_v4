extends SceneTree

func _init():
	print("Starting model patcher 2...")
	patch_all()
	print("Done patching models 2!")
	quit()

func patch_all():
	patch_unit("res://Scenes/Units/VoidSwarm/VoidCrawler.tscn", "VoidCrawler")
	patch_unit("res://Scenes/Units/VoidSwarm/VoidStalker.tscn", "VoidStalker")
	patch_unit("res://Scenes/Units/VoidSwarm/VoidSpitter.tscn", "VoidSpitter")
	patch_unit("res://Scenes/Units/VoidSwarm/VoidOverlord.tscn", "VoidOverlord")

func patch_unit(path: String, model_type: String):
	var packed = load(path)
	if not packed:
		print("Failed to load " + path)
		return
		
	var scene = packed.instantiate()
	
	# Clear old visual meshes
	for child in scene.get_children():
		if child is MeshInstance3D or child is CSGShape3D:
			child.free()
			
	# Rebuild!
	var pivot = Node3D.new()
	pivot.name = "VisualPivot"
	scene.add_child(pivot)
	pivot.owner = scene
	
	build_void(pivot, model_type)
		
	var new_packed = PackedScene.new()
	new_packed.pack(scene)
	ResourceSaver.save(new_packed, path)
	scene.free()
	print("Patched " + model_type)

func add_mesh(parent: Node, type: String, pos: Vector3, rot: Vector3, size: Vector3, mat: Material):
	var m = MeshInstance3D.new()
	if type == "Box":
		var bm = BoxMesh.new()
		bm.size = size
		m.mesh = bm
	elif type == "Cylinder":
		var cm = CylinderMesh.new()
		cm.height = size.y
		cm.bottom_radius = size.x
		cm.top_radius = size.z
		m.mesh = cm
	elif type == "Sphere":
		var sm = SphereMesh.new()
		sm.radius = size.x
		sm.height = size.x * 2.0
		m.mesh = sm
	elif type == "Capsule":
		var cap = CapsuleMesh.new()
		cap.radius = size.x
		cap.height = size.y
		m.mesh = cap
		
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot
	parent.add_child(m)
	m.owner = parent.owner
	return m
	
func make_mat(c: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = c
	return m
	
func build_void(pivot, type):
	var mat = make_mat(Color(0.2, 0.0, 0.3))
	var mat_glow = make_mat(Color(0.8, 0.1, 0.9))
	mat_glow.emission_enabled = true
	mat_glow.emission = Color(0.8, 0.1, 0.9)
	
	if type == "VoidCrawler":
		add_mesh(pivot, "Box", Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(1.5, 1, 2), mat)
		for i in range(6):
			var z = -0.8 + (i%3)*0.8
			var x = 1.0 if i < 3 else -1.0
			add_mesh(pivot, "Box", Vector3(x, 0.5, z), Vector3(0, 0, 45 if x>0 else -45), Vector3(1, 0.2, 0.2), mat)
	elif type == "VoidStalker":
		add_mesh(pivot, "Capsule", Vector3(0, 1.5, 0), Vector3(45, 0, 0), Vector3(0.5, 3.0, 0.5), mat)
		add_mesh(pivot, "Sphere", Vector3(0, 2.5, 1.0), Vector3.ZERO, Vector3(0.4, 0.4, 0.4), mat_glow)
	elif type == "VoidSpitter":
		add_mesh(pivot, "Sphere", Vector3(0, 1.5, 0), Vector3.ZERO, Vector3(1.2, 1.2, 1.2), mat)
		add_mesh(pivot, "Cylinder", Vector3(0, 1.5, 1.5), Vector3(90, 0, 0), Vector3(0.4, 1.5, 0.2), mat_glow)
	elif type == "VoidOverlord":
		add_mesh(pivot, "Capsule", Vector3(0, 4, 0), Vector3.ZERO, Vector3(2, 6, 2), mat)
		add_mesh(pivot, "Sphere", Vector3(0, 6, 1.5), Vector3.ZERO, Vector3(1, 1, 1), mat_glow)
		add_mesh(pivot, "Box", Vector3(2.5, 4, 0), Vector3(0, 0, 45), Vector3(3, 0.5, 1), mat)
		add_mesh(pivot, "Box", Vector3(-2.5, 4, 0), Vector3(0, 0, -45), Vector3(3, 0.5, 1), mat)
