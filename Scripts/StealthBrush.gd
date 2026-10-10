extends Area3D
class_name StealthBrush

@export var brush_radius: float = 5.5

func _ready():
	collision_layer = 0
	collision_mask = 1 | 2 # Detect units/creatures
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func setup_visuals(radius: float = 5.5):
	brush_radius = radius
	
	# Collision shape
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 4.0
	col.shape = cyl
	col.position.y = 2.0
	add_child(col)
	
	# Ground soil / bed disc
	var bed_mesh = MeshInstance3D.new()
	var bed_cyl = CylinderMesh.new()
	bed_cyl.top_radius = radius
	bed_cyl.bottom_radius = radius * 1.05
	bed_cyl.height = 0.08
	var bed_mat = StandardMaterial3D.new()
	bed_mat.albedo_color = Color(0.16, 0.38, 0.12)
	bed_mat.roughness = 0.9
	bed_mesh.mesh = bed_cyl
	bed_mesh.material_override = bed_mat
	bed_mesh.position.y = 0.04
	add_child(bed_mesh)
	
	# Dense clusters of tall grass blades
	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.24, 0.64, 0.18)
	grass_mat.roughness = 0.7
	grass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	var blade_box = BoxMesh.new()
	blade_box.size = Vector3(0.22, 2.5, 0.04)
	
	var blade_alt = BoxMesh.new()
	blade_alt.size = Vector3(0.18, 2.8, 0.04)
	
	var blade_mat2 = StandardMaterial3D.new()
	blade_mat2.albedo_color = Color(0.30, 0.72, 0.22)
	blade_mat2.roughness = 0.65
	blade_mat2.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	var clump_count = int(radius * 5.0)
	for i in range(clump_count):
		var angle = randf() * TAU
		var dist = randf_range(0.4, radius * 0.92)
		var clump_pos = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		
		var clump = Node3D.new()
		clump.position = clump_pos
		add_child(clump)
		
		# 3-4 splayed blades per clump
		var blades_in_clump = randi_range(3, 5)
		for b in range(blades_in_clump):
			var blade = MeshInstance3D.new()
			blade.mesh = blade_box if (b % 2 == 0) else blade_alt
			blade.material_override = grass_mat if (b % 2 == 0) else blade_mat2
			
			var blade_rot_y = randf() * TAU
			var blade_tilt = randf_range(-0.15, 0.15)
			blade.rotation = Vector3(blade_tilt, blade_rot_y, randf_range(-0.15, 0.15))
			blade.position = Vector3(randf_range(-0.15, 0.15), 1.25, randf_range(-0.15, 0.15))
			clump.add_child(blade)

func is_flying_unit(body: Node) -> bool:
	if "Plane" in body.name: return true
	if body.get("flight_height") != null: return true
	if body.get("is_flying") == true: return true
	if body.get("unit_attribute") == "Flying": return true
	if body is Node3D and body.global_position.y > 4.5: return true
	return false

func _on_body_entered(body: Node):
	if not body.is_in_group("Targetable"): return
	if is_flying_unit(body): return # Flying units cannot hide in tall grass!
	
	var count = body.get_meta("stealth_brush_count", 0) + 1
	body.set_meta("stealth_brush_count", count)
	body.set_meta("in_stealth_grass", true)
	body.set_meta("current_brush_zone", self)

func _on_body_exited(body: Node):
	if not is_instance_valid(body): return
	if body.has_meta("stealth_brush_count"):
		var count = max(0, body.get_meta("stealth_brush_count", 1) - 1)
		body.set_meta("stealth_brush_count", count)
		if count <= 0:
			body.set_meta("in_stealth_grass", false)
			if body.get_meta("current_brush_zone", null) == self:
				body.set_meta("current_brush_zone", null)
