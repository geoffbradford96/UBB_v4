extends CharacterBody3D

@export var spawn_interval: float = 3.5
@export var melee_damage: float = 40.0
@export var melee_range: float = 3.5

var spawn_timer: float = 0.0
var melee_timer: float = 0.0
var unit_attribute: String = "Organic"

var cell_scene = preload("res://Scenes/BeastCell.tscn")
var digestive_cell_scene = preload("res://Scenes/BeastDigestiveCell.tscn")

func _ready():
	add_to_group("Targetable")
	add_to_group("Beast")
	
	var mesh_node = Node3D.new()
	add_child(mesh_node)
	self.set_meta("mesh_node", mesh_node)
	
	# 1. Fleshy Basal Mound / Crater
	var mound = MeshInstance3D.new()
	var mound_mesh = CylinderMesh.new()
	mound_mesh.bottom_radius = 2.6
	mound_mesh.top_radius = 2.0
	mound_mesh.height = 0.6
	mound.mesh = mound_mesh
	var mound_mat = StandardMaterial3D.new()
	mound_mat.albedo_color = Color(0.18, 0.04, 0.25)
	mound_mat.roughness = 0.8
	mound.material_override = mound_mat
	mound.position.y = 0.3
	mesh_node.add_child(mound)
	
	# 2. Pulsing Fleshy Outer Lips
	var mouth = MeshInstance3D.new()
	mouth.mesh = TorusMesh.new()
	mouth.mesh.outer_radius = 2.2
	mouth.mesh.inner_radius = 1.15
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.08, 0.45)
	mat.roughness = 0.35
	mouth.material_override = mat
	mouth.position.y = 0.55
	mesh_node.add_child(mouth)
	
	# 3. Inner Throat Void (Bottomless Abyss)
	var throat = MeshInstance3D.new()
	var throat_mesh = CylinderMesh.new()
	throat_mesh.bottom_radius = 0.95
	throat_mesh.top_radius = 0.95
	throat_mesh.height = 0.4
	throat.mesh = throat_mesh
	var void_mat = StandardMaterial3D.new()
	void_mat.albedo_color = Color(0.01, 0.0, 0.02)
	void_mat.roughness = 1.0
	throat.material_override = void_mat
	throat.position.y = 0.45
	mesh_node.add_child(throat)
	
	# 4. Outer Ring: 14 Recurved Ivory Fangs
	var teeth_mat = StandardMaterial3D.new()
	teeth_mat.albedo_color = Color(0.9, 0.86, 0.78)
	teeth_mat.roughness = 0.3
	for i in range(14):
		var tooth = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		tm.top_radius = 0.0
		tm.bottom_radius = 0.2
		tm.height = 1.05
		tooth.mesh = tm
		tooth.material_override = teeth_mat
		var angle = i * (2.0 * PI / 14.0)
		tooth.position = Vector3(cos(angle) * 1.35, 0.7, sin(angle) * 1.35)
		tooth.rotation_degrees.x = -28
		tooth.rotation.y = -angle + PI/2.0
		mesh_node.add_child(tooth)
		
	# 5. Inner Ring: 8 Sharp Needle Teeth
	for i in range(8):
		var tooth = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		tm.top_radius = 0.0
		tm.bottom_radius = 0.12
		tm.height = 0.8
		tooth.mesh = tm
		tooth.material_override = teeth_mat
		var angle = i * (2.0 * PI / 8.0) + 0.25
		tooth.position = Vector3(cos(angle) * 0.85, 0.6, sin(angle) * 0.85)
		tooth.rotation_degrees.x = -35
		tooth.rotation.y = -angle + PI/2.0
		mesh_node.add_child(tooth)
		
	# 6. Pulsing Toxic Bile Pustules
	var bile_mat = StandardMaterial3D.new()
	bile_mat.albedo_color = Color(0.45, 0.85, 0.1)
	bile_mat.emission_enabled = true
	bile_mat.emission = Color(0.4, 0.85, 0.1)
	bile_mat.emission_energy_multiplier = 2.5
	for i in range(5):
		var pustule = MeshInstance3D.new()
		var pm = SphereMesh.new()
		pm.radius = 0.32
		pm.height = 0.45
		pustule.mesh = pm
		pustule.material_override = bile_mat
		var a = i * (2.0 * PI / 5.0) + 0.4
		pustule.position = Vector3(cos(a) * 2.1, 0.55, sin(a) * 2.1)
		mesh_node.add_child(pustule)

func _physics_process(delta):
	var mn = get_meta("mesh_node") if has_meta("mesh_node") else null
	if mn and is_instance_valid(mn):
		var t = Time.get_ticks_msec() * 0.004
		var s = sin(t) * 0.08
		mn.scale = Vector3(1.0 + s, 1.0 - s * 0.5, 1.0 + s)
		
	# Self-defense Melee Chomp on close intruders
	melee_timer -= delta
	if melee_timer <= 0.0:
		for node in get_tree().get_nodes_in_group("Targetable"):
			if not node.is_in_group("Beast") and is_instance_valid(node) and node != self:
				var hp = node.get_node_or_null("HealthComponent")
				if hp and hp.is_dead: continue
				if global_position.distance_to(node.global_position) <= melee_range:
					if hp:
						hp.take_damage(melee_damage)
						melee_timer = 1.2
						# Violent jaw clamp snap
						if mn and is_instance_valid(mn):
							var tw = create_tween()
							tw.tween_property(mn, "scale", Vector3(0.75, 1.5, 0.75), 0.08)
							tw.tween_property(mn, "scale", Vector3(1.0, 1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
						break
						
	# Periodic Cell Spawning
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		var cell_count = get_tree().get_nodes_in_group("Beast").size()
		if cell_count > 60: return
		
		# 60% chance for Spike Cell (Antibody), 40% chance for Digestive Acid Cell
		var cell_type = 1 if randf() < 0.4 else 0
		
		if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			if multiplayer.is_server():
				rpc("sync_spawn_cell", cell_type)
		else:
			sync_spawn_cell(cell_type)

@rpc("authority", "call_local", "reliable")
func sync_spawn_cell(cell_type: int = 0):
	var scn = digestive_cell_scene if cell_type == 1 else cell_scene
	if scn:
		var c = scn.instantiate()
		get_tree().current_scene.add_child(c)
		c.global_position = global_position + Vector3(0, 0.8, 0)
		c.add_to_group("Beast")
		
		# Regurgitation convulsive gulp animation
		var mn = get_meta("mesh_node") if has_meta("mesh_node") else null
		if mn and is_instance_valid(mn):
			var tw = create_tween()
			tw.tween_property(mn, "scale", Vector3(1.35, 0.6, 1.35), 0.1)
			tw.tween_property(mn, "scale", Vector3(1.0, 1.0, 1.0), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
