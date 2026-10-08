extends SceneTree

func _init():
	var path = "res://Scenes/Units/CheapGrunt.tscn"
	var packed = load(path)
	if packed:
		var scene = packed.instantiate()
		var mesh = scene.get_node_or_null("MeshInstance3D")
		if mesh:
			# Remove old cosmetics
			for c in mesh.get_children():
				if "Cosmetic" in c.name: c.queue_free()
				
			var helm = CSGSphere3D.new()
			helm.name = "Cosmetic_Helm"
			helm.radius = 0.55
			helm.position = Vector3(0, 0.4, 0)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.2, 0.3, 0.1) # Dark green
			mat.roughness = 0.9
			helm.material = mat
			mesh.add_child(helm)
			
			var r_arm = mesh.get_node_or_null("RightArm")
			if r_arm:
				# Clean weapons
				for c in r_arm.get_children():
					if "Weapon" in c.name: c.queue_free()
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
				
		var new_packed = PackedScene.new()
		new_packed.pack(scene)
		ResourceSaver.save(new_packed, path)
		print("Updated CheapGrunt cosmetics!")
	quit()
