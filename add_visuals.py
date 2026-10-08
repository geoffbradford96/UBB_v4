with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

funcs = '''
func _get_team_faction(team: String) -> String:
	for child in get_children():
		if child.has_method("get_class") and "BotAI" in child.get_script().resource_path:
			if child.my_team == team:
				if child.ai_profile == "Void Charcon": return "Void"
				if child.ai_profile == "The Great Beast Speaker": return "Rimworlders"
				if child.ai_profile == "Dominion Planet Commander": return "Dominion"
				var options = ["Dominion", "Void", "Rimworlders"]
				return options[randi() % options.size()]
	for p in players:
		if p.team == team:
			var deck = []
			if GameState.player_decks.has(p.profile):
				deck = GameState.player_decks[p.profile]
			var v = 0; var r = 0; var d = 0
			for c in deck:
				if "Void" in c: v += 1
				elif "Rimworlder" in c or "Sky" in c or "Stone" in c or "Giant" in c or "Great" in c: r += 1
				else: d += 1
			var mx = max(d, max(v, r))
			if mx == v and v > 0: return "Void"
			if mx == r and r > 0: return "Rimworlders"
			return "Dominion"
	var opts = ["Dominion", "Void", "Rimworlders"]
	return opts[randi() % opts.size()]

func _apply_faction_visuals():
	var teams = ["SideA", "SideB", "SideC", "SideD"]
	for team in teams:
		var faction = _get_team_faction(team)
		for node in get_tree().get_nodes_in_group(team):
			if "Base" in node.name or "Tower" in node.name:
				if "faction" in node: node.faction = faction
				_build_structure_mesh(node, faction, "Tower" in node.name)

func _build_structure_mesh(node, faction, is_tower):
	for c in node.get_children():
		if c is MeshInstance3D:
			c.queue_free()
			
	var mesh_node = Node3D.new()
	node.add_child(mesh_node)
	
	if faction == "Dominion":
		if is_tower:
			var cyl = MeshInstance3D.new()
			cyl.mesh = CylinderMesh.new(); cyl.mesh.height = 4.0; cyl.mesh.bottom_radius = 1.0; cyl.mesh.top_radius = 1.0
			var mat_silver = StandardMaterial3D.new()
			mat_silver.albedo_color = Color(0.8, 0.8, 0.9); mat_silver.metallic = 0.8
			cyl.material_override = mat_silver; cyl.position.y = 2.0
			mesh_node.add_child(cyl)
			var dome = MeshInstance3D.new()
			dome.mesh = SphereMesh.new(); dome.mesh.radius = 1.2
			dome.material_override = mat_silver; dome.position.y = 4.0
			mesh_node.add_child(dome)
		else:
			var box = MeshInstance3D.new()
			box.mesh = BoxMesh.new(); box.mesh.size = Vector3(5, 3, 5)
			var mat_gold = StandardMaterial3D.new()
			mat_gold.albedo_color = Color(1.0, 0.8, 0.0); mat_gold.metallic = 1.0
			box.material_override = mat_gold; box.position.y = 1.5
			mesh_node.add_child(box)
			
	elif faction == "Void":
		if is_tower:
			var eye_base = MeshInstance3D.new()
			eye_base.mesh = CylinderMesh.new(); eye_base.mesh.height = 3.0; eye_base.mesh.bottom_radius = 0.8; eye_base.mesh.top_radius = 0.8
			var mat_dark = StandardMaterial3D.new(); mat_dark.albedo_color = Color(0.1, 0.0, 0.2)
			eye_base.material_override = mat_dark; eye_base.position.y = 1.5
			mesh_node.add_child(eye_base)
			var eye = MeshInstance3D.new()
			eye.mesh = SphereMesh.new(); eye.mesh.radius = 1.5
			var mat_eye = StandardMaterial3D.new(); mat_eye.albedo_color = Color(0.9, 0.1, 0.9); mat_eye.emission_enabled = true; mat_eye.emission = Color(0.8, 0.0, 0.8)
			eye.material_override = mat_eye; eye.position.y = 3.5
			mesh_node.add_child(eye)
		else:
			var box = MeshInstance3D.new()
			box.mesh = BoxMesh.new(); box.mesh.size = Vector3(6, 4, 6)
			var mat_dark = StandardMaterial3D.new(); mat_dark.albedo_color = Color(0.1, 0.1, 0.1)
			box.material_override = mat_dark; box.position.y = 2.0
			mesh_node.add_child(box)
			var scar = MeshInstance3D.new()
			scar.mesh = BoxMesh.new(); scar.mesh.size = Vector3(4, 0.1, 4)
			var mat_scar = StandardMaterial3D.new(); mat_scar.albedo_color = Color(0.8, 0, 1.0); mat_scar.emission_enabled = true; mat_scar.emission = Color(0.8, 0, 1.0)
			scar.material_override = mat_scar; scar.position.y = 4.1
			scar.rotation_degrees.y = 45
			mesh_node.add_child(scar)
			
	elif faction == "Rimworlders":
		if is_tower:
			var mat_flesh = StandardMaterial3D.new(); mat_flesh.albedo_color = Color(0.2, 0.8, 0.3)
			for i in range(3):
				var stalk = MeshInstance3D.new()
				stalk.mesh = CapsuleMesh.new(); stalk.mesh.radius = 0.3; stalk.mesh.height = 3.0
				stalk.material_override = mat_flesh
				stalk.position.y = 1.5
				var angle = i * (3.14159 * 2.0 / 3.0)
				stalk.position.x = cos(angle) * 0.8; stalk.position.z = sin(angle) * 0.8
				stalk.rotation_degrees.x = sin(angle) * 15; stalk.rotation_degrees.z = -cos(angle) * 15
				mesh_node.add_child(stalk)
				var head = MeshInstance3D.new()
				head.mesh = SphereMesh.new(); head.mesh.radius = 0.6
				head.material_override = mat_flesh; head.position.y = 1.5
				stalk.add_child(head)
		else:
			var mat_beast = StandardMaterial3D.new(); mat_beast.albedo_color = Color(0.1, 0.6, 0.2); mat_beast.emission_enabled = true; mat_beast.emission = Color(0.0, 0.3, 0.1)
			var core = MeshInstance3D.new()
			core.mesh = SphereMesh.new(); core.mesh.radius = 3.0; core.mesh.height = 4.0
			core.material_override = mat_beast; core.position.y = 2.0
			mesh_node.add_child(core)
			for i in range(5):
				var tent = MeshInstance3D.new()
				tent.mesh = CapsuleMesh.new(); tent.mesh.radius = 0.8; tent.mesh.height = 5.0
				tent.material_override = mat_beast
				var angle = i * (3.14159 * 2.0 / 5.0)
				tent.position.x = cos(angle) * 2.5; tent.position.z = sin(angle) * 2.5; tent.position.y = 2.0
				tent.rotation_degrees.x = sin(angle) * 45; tent.rotation_degrees.z = -cos(angle) * 45
				mesh_node.add_child(tent)
'''

text = text + '\n' + funcs

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)
