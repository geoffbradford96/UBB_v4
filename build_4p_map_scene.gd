extends Node

func _ready():
	var packed = load("res://Scenes/Arena.tscn")
	if packed == null:
		print("Failed to load Arena.tscn")
		get_tree().quit()
		return
		
	var scene = packed.instantiate()
	scene.name = "Arena_4P"
	
	# Clear out old bases/towers
	for child in scene.get_children():
		if "Base" in child.name or "Tower" in child.name or "River" in child.name:
			child.queue_free()
			
	var tower_scene = load("res://Scenes/Tower.tscn")
	
	var teams = [
		{"name": "SideA", "pos": Vector3(0, 2.5, 80), "t_pos": Vector3(0, 0, 40)},
		{"name": "SideB", "pos": Vector3(0, 2.5, -80), "t_pos": Vector3(0, 0, -40)},
		{"name": "SideC", "pos": Vector3(-80, 2.5, 0), "t_pos": Vector3(-40, 0, 0)},
		{"name": "SideD", "pos": Vector3(80, 2.5, 0), "t_pos": Vector3(40, 0, 0)}
	]
	
	for t in teams:
		var base = CSGBox3D.new()
		base.name = t.name + "_Base"
		base.size = Vector3(10, 5, 10)
		base.position = t.pos
		base.use_collision = true
		base.add_to_group(t.name)
		var hp = load("res://Scripts/HealthComponent.gd").new()
		hp.name = "HealthComponent"
		hp.max_health = 1000
		base.add_child(hp)
		scene.add_child(base)
		
		var tower = tower_scene.instantiate()
		tower.name = t.name + "_Tower"
		tower.position = t.t_pos
		tower.add_to_group(t.name)
		scene.add_child(tower)
		
	var river1 = CSGBox3D.new()
	river1.name = "RiverLeft"
	river1.size = Vector3(20, 1.1, 200)
	river1.position = Vector3(-90, -0.5, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.4, 0.8) 
	river1.material = mat
	scene.add_child(river1)
	
	var river2 = river1.duplicate()
	river2.name = "RiverRight"
	river2.position = Vector3(90, -0.5, 0)
	scene.add_child(river2)
	
	var koth_area = Area3D.new()
	koth_area.name = "KotH_Zone"
	koth_area.position = Vector3(0, 0, 0)
	
	var koth_shape = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 15.0
	cyl.height = 10.0
	koth_shape.shape = cyl
	koth_area.add_child(koth_shape)
	
	var koth_mesh = MeshInstance3D.new()
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = 15.0
	cyl_mesh.bottom_radius = 15.0
	cyl_mesh.height = 0.5
	var koth_mat = StandardMaterial3D.new()
	koth_mat.albedo_color = Color(1.0, 0.8, 0.2, 0.5)
	koth_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cyl_mesh.material = koth_mat
	koth_mesh.mesh = cyl_mesh
	koth_area.add_child(koth_mesh)
	
	scene.add_child(koth_area)
	
	var new_packed = PackedScene.new()
	new_packed.pack(scene)
	ResourceSaver.save(new_packed, "res://Scenes/Arena_4P.tscn")
	
	print("Arena_4P generated successfully with 4 bases and KotH!")
	get_tree().quit()
