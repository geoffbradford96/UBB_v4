extends SceneTree

func _init():
	var cards_data = {
		"RimworlderGunner": {"cost": 2.0, "hp": 100.0, "is_melee": false, "desc": "Green translucent humanoid with a rifle."},
		"RimworlderMelee": {"cost": 1.5, "hp": 120.0, "is_melee": true, "desc": "Green translucent humanoid with a blade."},
		"RimworlderMutant": {"cost": 3.0, "hp": 180.0, "is_melee": true, "desc": "Mutated rimworlder wielding a massive tentacle."},
		"RimworlderMonstrous": {"cost": 5.0, "hp": 350.0, "is_melee": true, "desc": "A terrifyingly overgrown Rimworlder brute."},
		"SkyJellyfish": {"cost": 4.0, "hp": 150.0, "is_melee": false, "desc": "Floats in the sky and zaps enemies like a tesla coil."},
		"SkyBeetle": {"cost": 4.5, "hp": 400.0, "is_melee": true, "desc": "A heavy, armored flying beetle beast."},
		"StoneOctopus": {"cost": 6.0, "hp": 300.0, "is_melee": true, "desc": "Stone-shelled beast that unleashes a flurry of rapid attacks."},
		"GiantSquid": {"cost": 8.0, "hp": 800.0, "is_melee": true, "desc": "A colossal aquatic beast built to tear down heavy targets."}
	}
	
	for c_name in cards_data.keys():
		var data = cards_data[c_name]
		create_unit_and_card(c_name, data)
		
	quit()

func create_unit_and_card(unit_name: String, data: Dictionary):
	# 1. Create Scene
	var root = CharacterBody3D.new()
	root.name = unit_name
	
	# Add scripts and logic
	var unit_script = load("res://Scripts/Unit.gd")
	root.set_script(unit_script)
	
	root.set("is_melee", data["is_melee"])
	if unit_name == "StoneOctopus": root.set("attack_speed", 0.2) # Rapid attacks
	if unit_name == "SkyJellyfish": 
		root.set("attack_range", 10.0)
		root.set("attack_damage", 5.0)
		root.set("attack_speed", 0.5)
	if unit_name == "GiantSquid":
		root.set("attack_damage", 80.0)
		root.set("speed", 3.0)
		
	# Health Component
	var hc = Node.new()
	hc.name = "HealthComponent"
	var hc_script = load("res://Scripts/HealthComponent.gd")
	hc.set_script(hc_script)
	hc.set("max_health", data["hp"])
	root.add_child(hc)
	hc.owner = root
	
	# Collision
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.height = 2.0
	cyl.radius = 0.5
	if "Squid" in unit_name or "Beetle" in unit_name or "Monstrous" in unit_name:
		cyl.radius = 1.5
	col.shape = cyl
	col.position.y = 1.0
	root.add_child(col)
	col.owner = root
	
	# Mesh Root
	var mesh = Node3D.new()
	mesh.name = "MeshInstance3D"
	root.add_child(mesh)
	mesh.owner = root
	
	build_mesh_visuals(mesh, unit_name)
	
	# Animations
	var ap = AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root.add_child(ap)
	ap.owner = root
	
	var lib = AnimationLibrary.new()
	var anim_idle = Animation.new()
	var anim_walk = Animation.new()
	var anim_attack = Animation.new()
	anim_idle.length = 1.0; anim_idle.loop_mode = Animation.LOOP_LINEAR
	anim_walk.length = 1.0; anim_walk.loop_mode = Animation.LOOP_LINEAR
	anim_attack.length = 0.5
	lib.add_animation("idle", anim_idle)
	lib.add_animation("walk", anim_walk)
	lib.add_animation("attack", anim_attack)
	ap.add_animation_library("", lib)
	
	var scene = PackedScene.new()
	scene.pack(root)
	var scene_path = "res://Scenes/Units/" + unit_name + ".tscn"
	ResourceSaver.save(scene, scene_path)
	
	# 2. Create Card
	var card = load("res://Scripts/CardData.gd").new()
	card.card_name = unit_name
	card.card_type = "Rimworlder" if "Rimworlder" in unit_name else "Beast"
	card.description = data["desc"]
	card.cost = data["cost"]
	card.is_spell = false
	card.spawn_count = 1
	card.max_hp = data["hp"]
	card.is_melee = data["is_melee"]
	card.unit_scene = load(scene_path)
	
	ResourceSaver.save(card, "res://Data/Cards/" + unit_name + "Card.tres")
	print("Generated: ", unit_name)

func build_mesh_visuals(mesh: Node3D, unit_name: String):
	# Base translucent green material
	var mat_green = StandardMaterial3D.new()
	mat_green.albedo_color = Color(0.1, 0.9, 0.3, 0.65)
	mat_green.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_green.emission_enabled = true
	mat_green.emission = Color(0.0, 0.5, 0.1)
	
	var mat_stone = StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.4, 0.4, 0.45)
	mat_stone.roughness = 0.9
	
	var mat_beast = StandardMaterial3D.new()
	mat_beast.albedo_color = Color(0.2, 0.1, 0.4)
	
	if "Rimworlder" in unit_name:
		var body = MeshInstance3D.new()
		body.mesh = CapsuleMesh.new()
		body.mesh.radius = 0.4; body.mesh.height = 1.8
		body.material_override = mat_green
		body.position.y = 0.9
		mesh.add_child(body)
		body.owner = mesh.owner
		
		var head = MeshInstance3D.new()
		head.mesh = SphereMesh.new()
		head.mesh.radius = 0.3
		head.material_override = mat_green
		head.position.y = 1.9
		mesh.add_child(head)
		head.owner = mesh.owner
		
		if unit_name == "RimworlderGunner":
			var gun = MeshInstance3D.new()
			gun.mesh = BoxMesh.new()
			gun.mesh.size = Vector3(0.1, 0.1, 0.8)
			gun.position = Vector3(0.5, 1.0, -0.4)
			mesh.add_child(gun)
			gun.owner = mesh.owner
		elif unit_name == "RimworlderMelee":
			var blade = MeshInstance3D.new()
			blade.mesh = BoxMesh.new()
			blade.mesh.size = Vector3(0.05, 0.8, 0.1)
			blade.position = Vector3(0.5, 1.2, 0)
			blade.rotation_degrees.x = 45
			mesh.add_child(blade)
			blade.owner = mesh.owner
		elif unit_name == "RimworlderMutant":
			var tentacle = MeshInstance3D.new()
			tentacle.name = "RightArm_0"
			tentacle.mesh = CapsuleMesh.new()
			tentacle.mesh.radius = 0.2; tentacle.mesh.height = 1.5
			tentacle.material_override = mat_beast
			tentacle.position = Vector3(0.6, 1.0, -0.5)
			tentacle.rotation_degrees.x = -45
			mesh.add_child(tentacle)
			tentacle.owner = mesh.owner
		elif unit_name == "RimworlderMonstrous":
			body.mesh.radius = 0.8; body.mesh.height = 2.4
			body.position.y = 1.2
			head.position.y = 2.6
			
	elif unit_name == "SkyJellyfish":
		var dome = MeshInstance3D.new()
		dome.mesh = SphereMesh.new()
		dome.mesh.radius = 1.0; dome.mesh.height = 1.0
		dome.material_override = mat_green
		dome.position.y = 3.0 # Flying high
		mesh.add_child(dome)
		dome.owner = mesh.owner
		
		for i in range(6):
			var tentacle = MeshInstance3D.new()
			tentacle.mesh = CylinderMesh.new()
			tentacle.mesh.radius = 0.05; tentacle.mesh.height = 1.5
			tentacle.material_override = mat_green
			var angle = i * (PI / 3.0)
			tentacle.position = Vector3(cos(angle)*0.7, 2.0, sin(angle)*0.7)
			mesh.add_child(tentacle)
			tentacle.owner = mesh.owner
			
	elif unit_name == "SkyBeetle":
		var shell = MeshInstance3D.new()
		shell.mesh = SphereMesh.new()
		shell.mesh.radius = 1.2; shell.mesh.height = 1.0
		shell.material_override = mat_stone
		shell.position.y = 2.0 # Flying low
		mesh.add_child(shell)
		shell.owner = mesh.owner
		
	elif unit_name == "StoneOctopus":
		var shell = MeshInstance3D.new()
		shell.mesh = SphereMesh.new()
		shell.mesh.radius = 0.8
		shell.material_override = mat_stone
		shell.position.y = 1.0
		mesh.add_child(shell)
		shell.owner = mesh.owner
		
		for i in range(8):
			var arm = MeshInstance3D.new()
			arm.mesh = CapsuleMesh.new()
			arm.mesh.radius = 0.15; arm.mesh.height = 1.2
			arm.material_override = mat_beast
			var angle = i * (PI / 4.0)
			arm.position = Vector3(cos(angle)*0.8, 0.5, sin(angle)*0.8)
			arm.rotation_degrees.x = 45 if sin(angle) > 0 else -45
			arm.rotation_degrees.z = 45 if cos(angle) < 0 else -45
			mesh.add_child(arm)
			arm.owner = mesh.owner
			
	elif unit_name == "GiantSquid":
		var mantle = MeshInstance3D.new()
		mantle.mesh = CylinderMesh.new()
		mantle.mesh.top_radius = 0.2
		mantle.mesh.bottom_radius = 1.5
		mantle.mesh.height = 3.0
		mantle.material_override = mat_beast
		mantle.position.y = 3.0
		mesh.add_child(mantle)
		mantle.owner = mesh.owner
		
		for i in range(10):
			var tent = MeshInstance3D.new()
			tent.mesh = CapsuleMesh.new()
			tent.mesh.radius = 0.2; tent.mesh.height = 2.5
			tent.material_override = mat_beast
			var angle = i * (PI / 5.0)
			tent.position = Vector3(cos(angle)*1.0, 1.0, sin(angle)*1.0)
			mesh.add_child(tent)
			tent.owner = mesh.owner




