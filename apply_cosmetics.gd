extends SceneTree

func _init():
	print("--- Applying Cosmetics ---")
	apply_dominion()
	apply_void()
	print("--- Done ---")
	quit()

func add_material(mesh_node, mat):
	if mesh_node is MeshInstance3D:
		mesh_node.material_override = mat
	elif mesh_node is CSGShape3D:
		mesh_node.material = mat

func apply_dominion():
	var units = {
		"Grunt": "Army Helmet",
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
			
			# Clean old cosmetics if any
			for c in mesh.get_children():
				if "Cosmetic" in c.name:
					c.queue_free()
					
			if u == "Grunt":
				var helm = CSGSphere3D.new()
				helm.name = "Cosmetic_Helm"
				helm.radius = 0.55
				helm.position = Vector3(0, 0.4, 0)
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.2, 0.3, 0.1) # Dark green
				mat.roughness = 0.9
				helm.material = mat
				mesh.add_child(helm)
				
			elif u == "Sniper":
				var spartan = CSGBox3D.new()
				spartan.name = "Cosmetic_Spartan"
				spartan.size = Vector3(1.1, 1.0, 1.1)
				spartan.position = Vector3(0, 0.4, 0)
				
				# Crest
				var crest = CSGCylinder3D.new()
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
				
			elif u == "Medic":
				var c_v = CSGBox3D.new()
				c_v.name = "Cosmetic_CrossV"
				c_v.size = Vector3(0.6, 0.15, 0.1)
				c_v.position = Vector3(0, 0.3, -0.55) # Front of body
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
				
			elif u == "RepairMan":
				var wrench = CSGBox3D.new()
				wrench.name = "Cosmetic_Wrench"
				wrench.size = Vector3(0.1, 1.0, 0.1)
				
				# Try to find right arm
				var r_arm = mesh.get_node_or_null("RightArm")
				if r_arm:
					wrench.position = Vector3(0, -0.5, 0)
					r_arm.add_child(wrench)
				else:
					wrench.position = Vector3(0.6, 0, -0.5)
					mesh.add_child(wrench)
					
				var w_head = CSGCylinder3D.new()
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
				
			var new_packed = PackedScene.new()
			new_packed.pack(scene)
			ResourceSaver.save(new_packed, path)
			print("Updated cosmetics for: ", u)

func apply_void():
	var noise_tex = FastNoiseLite.new()
	noise_tex.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise_tex.frequency = 0.05
	
	var noise_tex_hair = FastNoiseLite.new()
	noise_tex_hair.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_tex_hair.frequency = 0.1
	
	var smooth_mat = StandardMaterial3D.new()
	smooth_mat.albedo_color = Color(0.1, 0.0, 0.2)
	smooth_mat.roughness = 0.1
	smooth_mat.metallic = 0.8
	
	var dir = DirAccess.open("res://Scenes/Units/VoidSwarm/")
	if dir:
		dir.list_dir_begin()
		var fn = dir.get_next()
		while fn != "":
			if fn.ends_with(".tscn"):
				var path = "res://Scenes/Units/VoidSwarm/" + fn
				var packed = load(path)
				if packed:
					var scene = packed.instantiate()
					var mesh = scene.get_node_or_null("MeshInstance3D")
					if mesh and mesh.mesh:
						if "Crawler" in fn or "Swarm" in fn:
							# Hairy / Rough
							var mat = StandardMaterial3D.new()
							mat.albedo_color = Color(0.2, 0.1, 0.3)
							mat.roughness = 1.0
							var noise_img = NoiseTexture2D.new()
							noise_img.noise = noise_tex_hair
							noise_img.as_normal_map = true
							mat.normal_enabled = true
							mat.normal_texture = noise_img
							mesh.set_surface_override_material(0, mat)
							print("Applied Hairy to ", fn)
							
						elif "Spitter" in fn or "Stalker" in fn:
							# Scaly
							var mat = StandardMaterial3D.new()
							mat.albedo_color = Color(0.15, 0.05, 0.25)
							mat.roughness = 0.6
							var noise_img = NoiseTexture2D.new()
							noise_img.noise = noise_tex
							noise_img.as_normal_map = true
							mat.normal_enabled = true
							mat.normal_texture = noise_img
							mesh.set_surface_override_material(0, mat)
							print("Applied Scaly to ", fn)
							
						else:
							# Smooth Overlords
							mesh.set_surface_override_material(0, smooth_mat)
							print("Applied Smooth to ", fn)
							
					var new_packed = PackedScene.new()
					new_packed.pack(scene)
					ResourceSaver.save(new_packed, path)
			fn = dir.get_next()
