extends SceneTree

func _init():
	print("Starting model patcher...")
	patch_all()
	print("Done patching models!")
	quit()

func patch_all():
	patch_unit("res://Scenes/Units/ScrapPlane.tscn", "ScrapPlane")
	patch_unit("res://Scenes/Units/ReachPlane.tscn", "ReachPlane")
	patch_unit("res://Scenes/Units/Plane.tscn", "Plane")
	
	patch_unit("res://Scenes/Units/ScrapTank.tscn", "ScrapTank")
	patch_unit("res://Scenes/Units/ReachTank.tscn", "ReachTank")
	
	patch_unit("res://Scenes/Units/SkyBeetle.tscn", "SkyBeetle")
	patch_unit("res://Scenes/Units/SkyJellyfish.tscn", "SkyJellyfish")
	patch_unit("res://Scenes/Units/StoneOctopus.tscn", "StoneOctopus")
	
	patch_unit("res://Scenes/Units/ScrapCommander.tscn", "ScrapCommander")
	patch_unit("res://Scenes/Units/ReachCommander.tscn", "ReachCommander")
	patch_unit("res://Scenes/Units/Commander.tscn", "Commander")
	
	patch_unit("res://Scenes/Units/VoidCrawler.tscn", "VoidCrawler")
	patch_unit("res://Scenes/Units/VoidStalker.tscn", "VoidStalker")
	patch_unit("res://Scenes/Units/VoidSpitter.tscn", "VoidSpitter")
	patch_unit("res://Scenes/Units/VoidOverlord.tscn", "VoidOverlord")

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
	
	if "Plane" in model_type:
		build_plane(pivot, model_type)
	elif "Tank" in model_type:
		build_tank(pivot, model_type)
	elif "Beetle" in model_type:
		build_beetle(pivot, model_type)
	elif "Jellyfish" in model_type:
		build_jellyfish(pivot, model_type)
	elif "Octopus" in model_type:
		build_octopus(pivot, model_type)
	elif "Commander" in model_type:
		build_commander(pivot, model_type)
	elif "Void" in model_type:
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
	
func build_plane(pivot, type):
	var col = Color(0.7, 0.7, 0.8)
	if "Scrap" in type: col = Color(0.6, 0.3, 0.1)
	elif "Reach" in type: col = Color(0.15, 0.15, 0.25)
	
	var mat = make_mat(col)
	var mat2 = make_mat(Color(0.2, 0.2, 0.2))
	# Body
	add_mesh(pivot, "Box", Vector3(0, 5, 0), Vector3.ZERO, Vector3(1, 1, 3), mat)
	# Wings
	add_mesh(pivot, "Box", Vector3(0, 5, 0), Vector3.ZERO, Vector3(5, 0.2, 1), mat)
	# Tail
	add_mesh(pivot, "Box", Vector3(0, 5.5, -1.2), Vector3.ZERO, Vector3(0.2, 1, 0.5), mat)
	# Propeller
	add_mesh(pivot, "Box", Vector3(0, 5, 1.6), Vector3.ZERO, Vector3(1.5, 0.1, 0.1), mat2)

func build_tank(pivot, type):
	var col = Color(0.2, 0.4, 0.1)
	if "Scrap" in type: col = Color(0.6, 0.3, 0.1)
	elif "Reach" in type: col = Color(0.15, 0.15, 0.25)
	var mat = make_mat(col)
	var mat_dark = make_mat(Color(0.1, 0.1, 0.1))
	# Base
	add_mesh(pivot, "Box", Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(3, 1, 4), mat)
	# Treads
	add_mesh(pivot, "Box", Vector3(1.6, 0.5, 0), Vector3.ZERO, Vector3(0.5, 1.2, 4.5), mat_dark)
	add_mesh(pivot, "Box", Vector3(-1.6, 0.5, 0), Vector3.ZERO, Vector3(0.5, 1.2, 4.5), mat_dark)
	# Turret
	add_mesh(pivot, "Sphere", Vector3(0, 1.5, 0), Vector3.ZERO, Vector3(1.2, 1.2, 1.2), mat)
	# Barrel
	add_mesh(pivot, "Cylinder", Vector3(0, 1.5, 1.5), Vector3(90, 0, 0), Vector3(0.2, 3, 0.2), mat_dark)

func build_beetle(pivot, type):
	var mat = make_mat(Color(0.4, 0.8, 0.2))
	var mat_wing = make_mat(Color(0.2, 0.9, 0.4))
	mat_wing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_wing.albedo_color.a = 0.5
	# Body
	add_mesh(pivot, "Sphere", Vector3(0, 4, 0), Vector3.ZERO, Vector3(1.5, 1.5, 1.5), mat)
	# Wings
	add_mesh(pivot, "Box", Vector3(1, 4.5, 0), Vector3(0, 45, 0), Vector3(2, 0.1, 1), mat_wing)
	add_mesh(pivot, "Box", Vector3(-1, 4.5, 0), Vector3(0, -45, 0), Vector3(2, 0.1, 1), mat_wing)

func build_jellyfish(pivot, type):
	var mat = make_mat(Color(0.2, 0.8, 1.0))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.5, 0.8)
	
	add_mesh(pivot, "Sphere", Vector3(0, 4, 0), Vector3.ZERO, Vector3(2, 2, 2), mat)
	for i in range(4):
		var ang = i * PI / 2.0
		add_mesh(pivot, "Capsule", Vector3(cos(ang), 2.5, sin(ang)), Vector3.ZERO, Vector3(0.2, 3, 0.2), mat)

func build_octopus(pivot, type):
	var mat = make_mat(Color(0.5, 0.5, 0.55)) # Stone
	add_mesh(pivot, "Sphere", Vector3(0, 2, 0), Vector3.ZERO, Vector3(1.5, 1.5, 1.5), mat)
	for i in range(8):
		var ang = i * PI / 4.0
		add_mesh(pivot, "Capsule", Vector3(cos(ang)*1.5, 1.0, sin(ang)*1.5), Vector3(45*cos(ang), 0, -45*sin(ang)), Vector3(0.3, 2, 0.3), mat)

func build_commander(pivot, type):
	var col = Color(1.0, 0.8, 0.1) # Gold
	if "Scrap" in type: col = Color(0.8, 0.4, 0.1)
	elif "Reach" in type: col = Color(0.2, 0.2, 0.3)
	var mat = make_mat(col)
	var mat_head = make_mat(Color(0.9, 0.9, 0.9))
	# Body
	add_mesh(pivot, "Capsule", Vector3(0, 1.5, 0), Vector3.ZERO, Vector3(0.8, 2.5, 0.8), mat)
	# Shoulders
	add_mesh(pivot, "Box", Vector3(1.0, 2.2, 0), Vector3.ZERO, Vector3(0.8, 0.8, 0.8), mat)
	add_mesh(pivot, "Box", Vector3(-1.0, 2.2, 0), Vector3.ZERO, Vector3(0.8, 0.8, 0.8), mat)
	# Head
	add_mesh(pivot, "Sphere", Vector3(0, 3.2, 0), Vector3.ZERO, Vector3(0.6, 0.6, 0.6), mat_head)
	# Weapon (Sword or Gun)
	add_mesh(pivot, "Box", Vector3(1.2, 1.5, 1.0), Vector3(45, 0, 0), Vector3(0.2, 2.0, 0.2), mat)

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
