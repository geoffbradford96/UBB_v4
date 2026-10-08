extends SceneTree

func _init():
	var dominion_dir = "res://Scenes/Units/"
	var void_dir = "res://Scenes/Units/VoidSwarm/"
	
	var files = []
	var dir = DirAccess.open(dominion_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn") and not file_name in ["Plane.tscn", "Tank.tscn"]:
				files.append({ "path": dominion_dir + file_name, "faction": "dominion" })
			file_name = dir.get_next()
			
	var vdir = DirAccess.open(void_dir)
	if vdir:
		vdir.list_dir_begin()
		var file_name = vdir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				files.append({ "path": void_dir + file_name, "faction": "void" })
			file_name = vdir.get_next()
			
	for f in files:
		var packed = load(f.path)
		if packed == null: continue
		var scene = packed.instantiate()
		
		# Find the main mesh
		var main_mesh = scene.get_node_or_null("MeshInstance3D")
		if main_mesh == null: continue
		
		# Clean up any old limbs if they exist
		for child in main_mesh.get_children():
			if "Limb" in child.name or "Leg" in child.name or "Arm" in child.name:
				child.queue_free()
				
		if f.faction == "dominion":
			_add_dominion_limbs(scene, main_mesh)
		elif f.faction == "void":
			_add_void_limbs(scene, main_mesh)
			
		var new_packed = PackedScene.new()
		new_packed.pack(scene)
		ResourceSaver.save(new_packed, f.path)
		
	print("Finished updating models!")
	quit()

func _add_dominion_limbs(owner_node, parent_mesh):
	# Left Arm
	var l_arm = MeshInstance3D.new()
	l_arm.name = "LeftArm"
	l_arm.mesh = CapsuleMesh.new()
	l_arm.position = Vector3(-0.6, 0.2, 0)
	l_arm.rotation_degrees = Vector3(0, 0, 45)
	l_arm.scale = Vector3(0.2, 0.6, 0.2)
	parent_mesh.add_child(l_arm)
	l_arm.owner = owner_node
	
	# Right Arm
	var r_arm = MeshInstance3D.new()
	r_arm.name = "RightArm"
	r_arm.mesh = CapsuleMesh.new()
	r_arm.position = Vector3(0.6, 0.2, 0)
	r_arm.rotation_degrees = Vector3(0, 0, -45)
	r_arm.scale = Vector3(0.2, 0.6, 0.2)
	parent_mesh.add_child(r_arm)
	r_arm.owner = owner_node
	
	# Left Leg
	var l_leg = MeshInstance3D.new()
	l_leg.name = "LeftLeg"
	l_leg.mesh = CapsuleMesh.new()
	l_leg.position = Vector3(-0.25, -0.6, 0)
	l_leg.scale = Vector3(0.25, 0.6, 0.25)
	parent_mesh.add_child(l_leg)
	l_leg.owner = owner_node
	
	# Right Leg
	var r_leg = MeshInstance3D.new()
	r_leg.name = "RightLeg"
	r_leg.mesh = CapsuleMesh.new()
	r_leg.position = Vector3(0.25, -0.6, 0)
	r_leg.scale = Vector3(0.25, 0.6, 0.25)
	parent_mesh.add_child(r_leg)
	r_leg.owner = owner_node
	
	# Match colors if possible
	if parent_mesh.mesh and parent_mesh.mesh is CapsuleMesh:
		var mat = parent_mesh.get_active_material(0)
		if mat:
			l_arm.mesh.material = mat
			r_arm.mesh.material = mat
			l_leg.mesh.material = mat
			r_leg.mesh.material = mat

func _add_void_limbs(owner_node, parent_mesh):
	# Rotate main mesh to be horizontal and lower it to be a crawling beast!
	parent_mesh.rotation_degrees = Vector3(90, 0, 0)
	parent_mesh.position.y = -0.3
	
	# Match colors if possible
	var mat = null
	if parent_mesh.mesh and parent_mesh.mesh is CapsuleMesh:
		mat = parent_mesh.get_active_material(0)

	var z_offsets = [-0.6, -0.2, 0.2, 0.6]
	for i in range(4):
		var l_leg = MeshInstance3D.new()
		l_leg.name = "LeftLeg_" + str(i)
		l_leg.mesh = CapsuleMesh.new()
		l_leg.position = Vector3(-0.6, 0, z_offsets[i])
		l_leg.rotation_degrees = Vector3(0, 0, 60)
		l_leg.scale = Vector3(0.1, 0.8, 0.1)
		if mat: l_leg.mesh.material = mat
		parent_mesh.add_child(l_leg)
		l_leg.owner = owner_node
		
		var r_leg = MeshInstance3D.new()
		r_leg.name = "RightLeg_" + str(i)
		r_leg.mesh = CapsuleMesh.new()
		r_leg.position = Vector3(0.6, 0, z_offsets[i])
		r_leg.rotation_degrees = Vector3(0, 0, -60)
		r_leg.scale = Vector3(0.1, 0.8, 0.1)
		if mat: r_leg.mesh.material = mat
		parent_mesh.add_child(r_leg)
		r_leg.owner = owner_node
