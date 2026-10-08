extends Node

func _ready():
	var packed = load("res://Scenes/Arena.tscn")
	if packed == null:
		get_tree().quit()
		return
		
	var scene = packed.instantiate()
	
	if scene.has_node("KotH_Zone"):
		scene.get_node("KotH_Zone").queue_free()
		
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
	ResourceSaver.save(new_packed, "res://Scenes/Arena.tscn")
	
	print("KotH_Zone added to Arena.tscn!")
	get_tree().quit()
