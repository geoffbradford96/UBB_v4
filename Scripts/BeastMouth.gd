extends CharacterBody3D

@export var spawn_interval: float = 3.0
var spawn_timer: float = 0.0

var cell_scene = preload("res://Scenes/BeastCell.tscn")

func _ready():
	add_to_group("Targetable")
	add_to_group("Beast")
	
	var mesh_node = Node3D.new()
	add_child(mesh_node)
	
	var mouth = MeshInstance3D.new()
	mouth.mesh = TorusMesh.new()
	mouth.mesh.outer_radius = 2.0
	mouth.mesh.inner_radius = 1.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.1, 0.4)
	mouth.material_override = mat
	mouth.position.y = 0.5
	mesh_node.add_child(mouth)
	
	var teeth_mat = StandardMaterial3D.new()
	teeth_mat.albedo_color = Color(0.8, 0.8, 0.8)
	for i in range(12):
		var tooth = MeshInstance3D.new()
		tooth.mesh = CylinderMesh.new()
		tooth.mesh.top_radius = 0
		tooth.mesh.bottom_radius = 0.2
		tooth.mesh.height = 1.0
		tooth.material_override = teeth_mat
		var angle = i * 30 * (3.14159/180.0)
		tooth.position = Vector3(cos(angle)*1.2, 0.5, sin(angle)*1.2)
		tooth.rotation_degrees.x = -30
		tooth.rotation_degrees.y = -angle * (180.0/3.14159)
		mesh_node.add_child(tooth)
		
	self.set_meta("mesh_node", mesh_node)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
	move_and_slide()
	
	var mn = get_meta("mesh_node")
	if mn:
		var s = sin(Time.get_ticks_msec()*0.005)*0.1
		mn.scale = Vector3(1.0 + s, 1.0, 1.0 + s)
		
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			if multiplayer.is_server():
				rpc("sync_spawn_cell")
		else:
			sync_spawn_cell()

@rpc("authority", "call_local", "reliable")
func sync_spawn_cell():
	if cell_scene:
		var c = cell_scene.instantiate()
		get_tree().current_scene.add_child(c)
		c.global_position = global_position + Vector3(0, 1.0, 0)
		c.add_to_group("Beast")
