extends SceneTree

func _init():
	print("--- Re-applying Cosmetics & Weapons WITH OWNER ---")
	apply_dominion()
	print("--- Done ---")
	quit()

func set_owner_recursive(node, root):
	if node != root:
		node.owner = root
	for child in node.get_children():
		set_owner_recursive(child, root)

func apply_dominion():
	var units = {
		"CheapGrunt": "Army Helmet",
		"Sniper": "Spartan Helmet",
		"Medic": "Red Cross",
		"RepairMan": "Wrench",
		"Assassin": "HUD Visor"
	}
	
	for u in units.keys():
		var path = "res://Scenes/Units/" + u + ".tscn"
		var packed = load(path)
		if packed:
			var scene = packed.instantiate()
			var mesh = scene.get_node_or_null("MeshInstance3D")
			if not mesh: continue
			
			for c in mesh.get_children():
				if "Cosmetic" in c.name: c.queue_free()
				
			var r_arm = mesh.get_node_or_null("RightArm")
			if r_arm:
				for c in r_arm.get_children():
					if "Weapon" in c.name: c.queue_free()
			
			# COSMETICS
			if u == "CheapGrunt":
				var helm = CSGSphere3D.new()
				helm.name = "Cosmetic_Helm"
				helm.radius = 0.55
				helm.position = Vector3(0, 0.4, 0)
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.2, 0.3, 0.1)
				mat.roughness = 0.9
				helm.material = mat
				mesh.add_child(helm)
				
				if r_arm:
					var baton = CSGCylinder3D.new()
					baton.name = "Weapon_Baton"
					baton.radius = 0.05
					baton.height = 0.6
					baton.position = Vector3(0, -0.5, -0.2)
					baton.rotation_degrees = Vector3(-30, 0, 0)
					var w_mat = StandardMaterial3D.new()
					w_mat.albedo_color = Color(0.2, 0.2, 0.2)
					w_mat.metallic = 0.8
					baton.material = w_mat
					r_arm.add_child(baton)
					
			elif u == "Sniper":
				var spartan = CSGBox3D.new()
				spartan.name = "Cosmetic_Spartan"
				spartan.size = Vector3(1.1, 1.0, 1.1)
				spartan.position = Vector3(0, 0.4, 0)
				
				var crest = CSGCylinder3D.new()
				crest.name = "Cosmetic_Crest"
				crest.radius = 0.1
				crest.height = 1.2
				crest.position = Vector3(0, 0.6, 0)
				crest.rotation_degrees = Vector3(90, 0, 0)
				var cmat = StandardMaterial3D.new()
				cmat.albedo_color = Color(0.8, 0.1, 0.1)
				crest.material = cmat
				spartan.add_child(crest)
				
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.3, 0.3, 0.35)
				mat.metallic = 0.6
				spartan.material = mat
				mesh.add_child(spartan)
				
				if r_arm:
					var rifle = CSGBox3D.new()
					rifle.name = "Weapon_Rifle"
					rifle.size = Vector3(0.1, 0.1, 0.8)
					rifle.position = Vector3(0, -0.4, -0.4)
					var w_mat = StandardMaterial3D.new()
					w_mat.albedo_color = Color(0.2, 0.2, 0.2)
					w_mat.metallic = 0.8
					rifle.material = w_mat
					r_arm.add_child(rifle)
				
			elif u == "Medic":
				var c_v = CSGBox3D.new()
				c_v.name = "Cosmetic_CrossV"
				c_v.size = Vector3(0.6, 0.15, 0.1)
				c_v.position = Vector3(0, 0.3, -0.55)
				c_v.rotation_degrees = Vector3(0, 0, 90)
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.9, 0.1, 0.1)
				mat.emission_enabled = true
				mat.emission = Color(0.9, 0.1, 0.1)
				c_v.material = mat
				mesh.add_child(c_v)
				
				var c_h = CSGBox3D.new()
				c_h.name = "Cosmetic_CrossH"
				c_h.size = Vector3(0.6, 0.15, 0.1)
				c_h.position = Vector3(0, 0.3, -0.55)
				c_h.material = mat
				mesh.add_child(c_h)
				
				if r_arm:
					var pistol = CSGCombiner3D.new()
					pistol.name = "Weapon_Pistol"
					var barrel = CSGBox3D.new()
					barrel.size = Vector3(0.1, 0.1, 0.3)
					barrel.position = Vector3(0, -0.4, -0.2)
					var grip = CSGBox3D.new()
					grip.size = Vector3(0.1, 0.2, 0.1)
					grip.position = Vector3(0, -0.5, -0.05)
					grip.rotation_degrees = Vector3(20, 0, 0)
					pistol.add_child(barrel)
					pistol.add_child(grip)
					var w_mat = StandardMaterial3D.new()
					w_mat.albedo_color = Color(0.2, 0.2, 0.2)
					w_mat.metallic = 0.8
					pistol.material_override = w_mat
					r_arm.add_child(pistol)
				
			elif u == "RepairMan":
				var wrench = CSGBox3D.new()
				wrench.name = "Weapon_Wrench"
				wrench.size = Vector3(0.1, 1.0, 0.1)
				var w_head = CSGCylinder3D.new()
				w_head.name = "Weapon_WrenchHead"
				w_head.radius = 0.2
				w_head.height = 0.15
				w_head.position = Vector3(0, 0.5, 0)
				w_head.rotation_degrees = Vector3(90, 0, 0)
				var wmat = StandardMaterial3D.new()
				wmat.albedo_color = Color(0.5, 0.5, 0.5)
				wmat.metallic = 0.8
				wrench.material = wmat
				w_head.material = wmat
				wrench.add_child(w_head)
				
				if r_arm:
					wrench.position = Vector3(0, -0.5, -0.2)
					wrench.rotation_degrees = Vector3(-30, 0, 0)
					r_arm.add_child(wrench)
					
				if r_arm:
					var pistol = CSGCombiner3D.new()
					pistol.name = "Weapon_Pistol"
					var barrel = CSGBox3D.new()
					barrel.size = Vector3(0.1, 0.1, 0.3)
					barrel.position = Vector3(0, -0.4, -0.2)
					var grip = CSGBox3D.new()
					grip.size = Vector3(0.1, 0.2, 0.1)
					grip.position = Vector3(0, -0.5, -0.05)
					grip.rotation_degrees = Vector3(20, 0, 0)
					pistol.add_child(barrel)
					pistol.add_child(grip)
					var wp_mat = StandardMaterial3D.new()
					wp_mat.albedo_color = Color(0.2, 0.2, 0.2)
					wp_mat.metallic = 0.8
					pistol.material_override = wp_mat
					r_arm.add_child(pistol)
				
			elif u == "Assassin":
				var hud = CSGBox3D.new()
				hud.name = "Cosmetic_HUD"
				hud.size = Vector3(0.6, 0.2, 0.1)
				hud.position = Vector3(0, 0.5, -0.52)
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.1, 0.9, 0.9)
				mat.emission_enabled = true
				mat.emission = Color(0.1, 0.9, 0.9)
				hud.material = mat
				mesh.add_child(hud)
				
				if r_arm:
					var blade = CSGBox3D.new()
					blade.name = "Weapon_Blade"
					blade.size = Vector3(0.05, 0.4, 0.1)
					blade.position = Vector3(0, -0.6, -0.1)
					blade.rotation_degrees = Vector3(-45, 0, 0)
					var w_mat = StandardMaterial3D.new()
					w_mat.albedo_color = Color(0.2, 0.2, 0.2)
					w_mat.metallic = 0.8
					blade.material = w_mat
					r_arm.add_child(blade)
					
			set_owner_recursive(scene, scene)
			
			var new_packed = PackedScene.new()
			new_packed.pack(scene)
			ResourceSaver.save(new_packed, path)
			print("Fixed cosmetics/weapons WITH OWNER for: ", u)
