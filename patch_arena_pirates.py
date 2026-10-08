with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

# Add Scrap and Reach to _get_team_faction
old_get = '''				if child.ai_profile == "Dominion Planet Commander": return "Dominion"
				var options = ["Dominion", "Void", "Rimworlders"]'''

new_get = '''				if child.ai_profile == "Dominion Planet Commander": return "Dominion"
				if child.ai_profile == "The Scrap Pirate King": return "Scrap"
				if child.ai_profile == "The Reach Queen": return "Reach"
				var options = ["Dominion", "Void", "Rimworlders", "Scrap", "Reach"]'''
text = text.replace(old_get, new_get)

old_get2 = '''			var mx = max(d, max(v, r))
			if mx == v and v > 0: return "Void"
			if mx == r and r > 0: return "Rimworlders"
			return "Dominion"
	var opts = ["Dominion", "Void", "Rimworlders"]'''

new_get2 = '''			var s = 0; var reach = 0
			for c in deck:
				if "Scrap" in c: s += 1
				elif "Reach" in c: reach += 1
			var mx = max(d, max(v, max(r, max(s, reach))))
			if mx == v and v > 0: return "Void"
			if mx == r and r > 0: return "Rimworlders"
			if mx == s and s > 0: return "Scrap"
			if mx == reach and reach > 0: return "Reach"
			return "Dominion"
	var opts = ["Dominion", "Void", "Rimworlders", "Scrap", "Reach"]'''
text = text.replace(old_get2, new_get2)

# Add Visuals to _build_structure_mesh
old_visual = '''		else:
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
				mesh_node.add_child(tent)'''

new_visual = old_visual + '''
	elif faction == "Scrap":
		if is_tower:
			var p = MeshInstance3D.new()
			p.mesh = CylinderMesh.new(); p.mesh.height = 4.0; p.mesh.top_radius = 0.5
			var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.5, 0.2, 0.1); mat.metallic = 0.8
			p.material_override = mat; p.position.y = 2.0
			mesh_node.add_child(p)
			var g = MeshInstance3D.new()
			g.mesh = BoxMesh.new(); g.mesh.size = Vector3(1.2, 1.2, 1.2)
			var gm = StandardMaterial3D.new(); gm.albedo_color = Color(0.1, 0.9, 0.2); gm.emission_enabled = true; gm.emission = Color(0.1, 0.9, 0.2)
			g.material_override = gm; g.position.y = 4.0
			mesh_node.add_child(g)
		else:
			var m = MeshInstance3D.new()
			m.mesh = BoxMesh.new(); m.mesh.size = Vector3(6, 3, 6)
			var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.4, 0.2, 0.1); mat.metallic = 0.6
			m.material_override = mat; m.position.y = 1.5
			mesh_node.add_child(m)
			for i in range(6):
				var s = MeshInstance3D.new()
				s.mesh = CylinderMesh.new(); s.mesh.top_radius = 0; s.mesh.height = 3.0
				var sm = StandardMaterial3D.new(); sm.albedo_color = Color(0.2, 0.2, 0.2)
				s.material_override = sm; s.position.y = 3.0
				s.position.x = randf_range(-2, 2); s.position.z = randf_range(-2, 2)
				s.rotation_degrees.x = randf_range(-30, 30); s.rotation_degrees.z = randf_range(-30, 30)
				mesh_node.add_child(s)
	elif faction == "Reach":
		if is_tower:
			var p = MeshInstance3D.new()
			p.mesh = CylinderMesh.new(); p.mesh.height = 5.0; p.mesh.radius = 1.2
			var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.15, 0.15, 0.2); mat.metallic = 1.0
			p.material_override = mat; p.position.y = 2.5
			mesh_node.add_child(p)
			var s = MeshInstance3D.new()
			s.mesh = SphereMesh.new(); s.mesh.radius = 1.5
			var sm = StandardMaterial3D.new(); sm.albedo_color = Color(0.8, 0.1, 0.1); sm.emission_enabled = true; sm.emission = Color(0.8, 0.1, 0.1)
			s.material_override = sm; s.position.y = 5.5
			mesh_node.add_child(s)
		else:
			var m = MeshInstance3D.new()
			m.mesh = BoxMesh.new(); m.mesh.size = Vector3(5.5, 4, 5.5)
			var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.15, 0.15, 0.2); mat.metallic = 1.0
			m.material_override = mat; m.position.y = 2.0
			mesh_node.add_child(m)
			var s = MeshInstance3D.new()
			s.mesh = CylinderMesh.new(); s.mesh.top_radius = 0.5; s.mesh.bottom_radius=3.0; s.mesh.height = 2.5
			var sm = StandardMaterial3D.new(); sm.albedo_color = Color(0.8, 0.1, 0.1); sm.emission_enabled = true; sm.emission = Color(0.5, 0.0, 0.0)
			s.material_override = sm; s.position.y = 5.0
			mesh_node.add_child(s)'''

text = text.replace(old_visual, new_visual)

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)
