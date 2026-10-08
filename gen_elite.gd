extends SceneTree

func _init():
	print("Generating Elite Units...")
	generate_heavy_tank()
	generate_rocket_inf()
	generate_mine_inf()
	generate_boxy()
	generate_spider()
	print("Done")
	quit()

func save_scene(node, path):
	var pack = PackedScene.new()
	pack.pack(node)
	ResourceSaver.save(pack, path)

func set_owner_recursive(node, root):
	if node != root:
		node.owner = root
	for child in node.get_children():
		set_owner_recursive(child, root)

func get_mesh(scene):
	return scene.get_node_or_null("MeshInstance3D")

func generate_heavy_tank():
	var p = load("res://Scenes/Units/Tank.tscn")
	var scene = p.instantiate()
	scene.name = "HeavyTank"
	scene.set("speed", 2.0)
	scene.set("damage", 60.0)
	
	var hp = scene.get_node_or_null("HealthComponent")
	if hp:
		hp.set("max_health", 450)
	
	var m = get_mesh(scene)
	if m:
		m.scale.x = 1.6
		m.scale.z = 1.3
		
		var gun1 = CSGCylinder3D.new()
		gun1.name = "MainGunL"
		gun1.radius = 0.2
		gun1.height = 2.0
		gun1.position = Vector3(-0.4, 1.5, -1.0)
		gun1.rotation_degrees = Vector3(90, 0, 0)
		
		var gun2 = CSGCylinder3D.new()
		gun2.name = "MainGunR"
		gun2.radius = 0.2
		gun2.height = 2.0
		gun2.position = Vector3(0.4, 1.5, -1.0)
		gun2.rotation_degrees = Vector3(90, 0, 0)
		
		var mg1 = CSGBox3D.new()
		mg1.name = "MG_L"
		mg1.size = Vector3(0.1, 0.1, 0.6)
		mg1.position = Vector3(-0.8, 0.8, -1.2)
		
		var mg2 = CSGBox3D.new()
		mg2.name = "MG_R"
		mg2.size = Vector3(0.1, 0.1, 0.6)
		mg2.position = Vector3(0.8, 0.8, -1.2)
		
		m.add_child(gun1)
		m.add_child(gun2)
		m.add_child(mg1)
		m.add_child(mg2)
		
	set_owner_recursive(scene, scene)
	save_scene(scene, "res://Scenes/Units/HeavyTank.tscn")

func generate_rocket_inf():
	var p = load("res://Scenes/Units/Sniper.tscn")
	var scene = p.instantiate()
	scene.name = "RocketInfantry"
	scene.set("speed", 1.8)
	scene.set("attack_damage", 80.0)
	
	var m = get_mesh(scene)
	if m:
		var r_arm = m.get_node_or_null("RightArm")
		if r_arm:
			for c in r_arm.get_children():
				if "Weapon" in c.name: c.queue_free()
			
			var bazooka = CSGCylinder3D.new()
			bazooka.name = "Weapon_Bazooka"
			bazooka.radius = 0.15
			bazooka.height = 1.0
			bazooka.position = Vector3(0.1, 0.2, -0.2)
			bazooka.rotation_degrees = Vector3(90, 0, 0)
			
			var b_mat = StandardMaterial3D.new()
			b_mat.albedo_color = Color(0.2, 0.4, 0.2)
			bazooka.material = b_mat
			r_arm.add_child(bazooka)
			
	set_owner_recursive(scene, scene)
	save_scene(scene, "res://Scenes/Units/RocketInfantry.tscn")

func generate_mine_inf():
	var p = load("res://Scenes/Units/RepairMan.tscn")
	var scene = p.instantiate()
	scene.name = "LandMineInfantry"
	scene.set_script(load("res://Scripts/LandMineInfantry.gd"))
	
	var m = get_mesh(scene)
	if m:
		var r_arm = m.get_node_or_null("RightArm")
		if r_arm:
			for c in r_arm.get_children():
				if "Weapon" in c.name and "Wrench" in c.name: c.queue_free()
	
	set_owner_recursive(scene, scene)
	save_scene(scene, "res://Scenes/Units/LandMineInfantry.tscn")

func generate_boxy():
	var scene = CharacterBody3D.new()
	scene.name = "BoxyWalker"
	scene.set_script(load("res://Scripts/Unit.gd"))
	
	var coll = CollisionShape3D.new()
	coll.name = "CollisionShape3D"
	var shp = CapsuleShape3D.new()
	shp.radius = 0.5
	shp.height = 1.5
	coll.shape = shp
	coll.position = Vector3(0, 0.75, 0)
	scene.add_child(coll)
	
	var hp = Node.new()
	hp.name = "HealthComponent"
	hp.set_script(load("res://Scripts/HealthComponent.gd"))
	hp.set("max_health", 250)
	scene.add_child(hp)
	
	var mesh = CSGBox3D.new()
	mesh.name = "MeshInstance3D"
	mesh.size = Vector3(1.0, 1.0, 1.0)
	mesh.position = Vector3(0, 0.8, 0)
	
	for i in range(4):
		var leg = CSGBox3D.new()
		leg.name = "LeftLeg" if i%2==0 else "RightLeg"
		leg.name += "_" + str(i)
		leg.size = Vector3(0.2, 0.6, 0.2)
		var lx = 0.4 if i%2==0 else -0.4
		var lz = 0.4 if i<2 else -0.4
		leg.position = Vector3(lx, -0.5, lz)
		mesh.add_child(leg)
	
	for i in range(4):
		var mg = CSGBox3D.new()
		mg.name = "MG_" + str(i)
		mg.size = Vector3(0.1, 0.1, 0.6)
		var mx = 0.55 if i%2==0 else -0.55
		var my = 0.2
		var mz = -0.3 if i<2 else 0.3
		mg.position = Vector3(mx, my, mz)
		mesh.add_child(mg)
		
	scene.add_child(mesh)
	
	scene.set("speed", 2.5)
	scene.set("attack_speed", 4.0)
	scene.set("attack_damage", 10.0)
	scene.set("attack_range", 18.0)
	
	set_owner_recursive(scene, scene)
	save_scene(scene, "res://Scenes/Units/BoxyWalker.tscn")

func generate_spider():
	var scene = CharacterBody3D.new()
	scene.name = "SpiderTank"
	scene.set_script(load("res://Scripts/Unit.gd"))
	
	var coll = CollisionShape3D.new()
	coll.name = "CollisionShape3D"
	var shp = SphereShape3D.new()
	shp.radius = 1.0
	coll.shape = shp
	coll.position = Vector3(0, 1.0, 0)
	scene.add_child(coll)
	
	var hp = Node.new()
	hp.name = "HealthComponent"
	hp.set_script(load("res://Scripts/HealthComponent.gd"))
	hp.set("max_health", 200)
	scene.add_child(hp)
	
	var mesh = CSGSphere3D.new()
	mesh.name = "MeshInstance3D"
	mesh.radius = 0.8
	mesh.position = Vector3(0, 1.2, 0)
	
	var barrel = CSGCylinder3D.new()
	barrel.name = "SniperBarrel"
	barrel.radius = 0.1
	barrel.height = 3.0
	barrel.position = Vector3(0, 0, -1.5)
	barrel.rotation_degrees = Vector3(90, 0, 0)
	mesh.add_child(barrel)
	
	for i in range(4):
		var leg = CSGCylinder3D.new()
		leg.name = "LeftLeg" if i%2==0 else "RightLeg"
		leg.name += "_" + str(i)
		leg.radius = 0.1
		leg.height = 2.0
		var rot = i * 90 + 45
		leg.rotation_degrees = Vector3(-45, rot, 0)
		leg.position = Vector3(cos(deg_to_rad(rot))*0.8, -0.5, -sin(deg_to_rad(rot))*0.8)
		mesh.add_child(leg)
		
	scene.add_child(mesh)
	
	scene.set("speed", 3.0)
	scene.set("attack_speed", 0.5)
	scene.set("attack_damage", 60.0)
	scene.set("attack_range", 35.0)
	
	set_owner_recursive(scene, scene)
	save_scene(scene, "res://Scenes/Units/SpiderTank.tscn")
