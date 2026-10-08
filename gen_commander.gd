extends SceneTree

func _init():
	var cards_data = {
		"GreatBeastSpeaker": {"cost": 0.0, "hp": 500.0, "is_melee": false, "desc": "The commander of the Rimworlders. Can summon beasts from the void."}
	}
	
	for c_name in cards_data.keys():
		var data = cards_data[c_name]
		create_unit_and_card(c_name, data)
		
	quit()

func create_unit_and_card(unit_name: String, data: Dictionary):
	var root = CharacterBody3D.new()
	root.name = unit_name
	
	var unit_script = load("res://Scripts/Unit.gd")
	root.set_script(unit_script)
	root.set("is_melee", data["is_melee"])
	root.set("attack_range", 12.0)
	root.set("attack_damage", 10.0)
	
	var hc = Node.new()
	hc.name = "HealthComponent"
	var hc_script = load("res://Scripts/HealthComponent.gd")
	hc.set_script(hc_script)
	hc.set("max_health", data["hp"])
	root.add_child(hc)
	hc.owner = root
	
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.height = 2.0
	cyl.radius = 0.5
	col.shape = cyl
	col.position.y = 1.0
	root.add_child(col)
	col.owner = root
	
	var mesh = Node3D.new()
	mesh.name = "MeshInstance3D"
	root.add_child(mesh)
	mesh.owner = root
	
	build_mesh_visuals(mesh, unit_name)
	
	var ap = AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root.add_child(ap)
	ap.owner = root
	
	var lib = AnimationLibrary.new()
	var anim_idle = Animation.new(); anim_idle.length = 1.0; anim_idle.loop_mode = Animation.LOOP_LINEAR
	var anim_walk = Animation.new(); anim_walk.length = 1.0; anim_walk.loop_mode = Animation.LOOP_LINEAR
	var anim_attack = Animation.new(); anim_attack.length = 0.5
	lib.add_animation("idle", anim_idle)
	lib.add_animation("walk", anim_walk)
	lib.add_animation("attack", anim_attack)
	ap.add_animation_library("", lib)
	
	var scene = PackedScene.new()
	scene.pack(root)
	var scene_path = "res://Scenes/Units/" + unit_name + ".tscn"
	ResourceSaver.save(scene, scene_path)
	
	var card = load("res://Scripts/CardData.gd").new()
	card.card_name = "Great Beast Speaker"
	card.card_type = "Commander"
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
	var mat_green = StandardMaterial3D.new()
	mat_green.albedo_color = Color(0.1, 0.9, 0.3, 0.65)
	mat_green.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_green.emission_enabled = true
	mat_green.emission = Color(0.0, 0.5, 0.1)
	
	var body = MeshInstance3D.new()
	body.mesh = CapsuleMesh.new()
	body.mesh.radius = 0.5; body.mesh.height = 2.0
	body.material_override = mat_green
	body.position.y = 1.0
	mesh.add_child(body)
	body.owner = mesh.owner
	
	var head = MeshInstance3D.new()
	head.mesh = SphereMesh.new()
	head.mesh.radius = 0.4
	head.material_override = mat_green
	head.position.y = 2.2
	mesh.add_child(head)
	head.owner = mesh.owner
	
	var staff = MeshInstance3D.new()
	staff.mesh = CylinderMesh.new()
	staff.mesh.radius = 0.05
	staff.mesh.height = 2.5
	staff.position = Vector3(0.6, 1.2, 0)
	mesh.add_child(staff)
	staff.owner = mesh.owner
