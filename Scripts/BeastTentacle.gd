extends CharacterBody3D

@export var damage: float = 45.0
@export var attack_range: float = 14.0
@export var attack_rate: float = 1.2

var current_target: Node3D = null
var attack_timer: float = 0.0
var unit_attribute: String = "Organic"

func _ready():
	add_to_group("Targetable")
	add_to_group("Beast")
	
	# Procedural Multi-Segmented Eldritch Tentacle Model
	var mesh_node = Node3D.new()
	add_child(mesh_node)
	self.set_meta("mesh_node", mesh_node)
	
	var flesh_mat = StandardMaterial3D.new()
	flesh_mat.albedo_color = Color(0.28, 0.06, 0.38)
	flesh_mat.roughness = 0.4
	
	var bone_mat = StandardMaterial3D.new()
	bone_mat.albedo_color = Color(0.88, 0.84, 0.74)
	bone_mat.roughness = 0.5
	
	var sucker_mat = StandardMaterial3D.new()
	sucker_mat.albedo_color = Color(0.65, 0.15, 0.35)
	sucker_mat.roughness = 0.2
	
	# 1. Fleshy Basal Root Collar
	var collar = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.bottom_radius = 2.2
	cm.top_radius = 1.6
	cm.height = 0.8
	collar.mesh = cm
	collar.material_override = flesh_mat
	collar.position.y = 0.4
	mesh_node.add_child(collar)
	
	# 2. Four-Tier Segmented Trunk
	var seg_heights = [1.4, 4.0, 6.6, 9.0]
	var seg_radii = [[1.25, 1.05], [1.05, 0.8], [0.8, 0.55], [0.55, 0.2]]
	for i in range(4):
		var seg = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.bottom_radius = seg_radii[i][0]
		cyl.top_radius = seg_radii[i][1]
		cyl.height = 2.8 if i < 3 else 2.5
		seg.mesh = cyl
		seg.material_override = flesh_mat
		seg.position = Vector3(0, seg_heights[i], (i * 0.15))
		mesh_node.add_child(seg)
		
	# 3. Six Dorsal Barbed Spines (along the rear)
	for i in range(6):
		var spine = MeshInstance3D.new()
		var sm = CylinderMesh.new()
		sm.top_radius = 0.0
		sm.bottom_radius = 0.14
		sm.height = 0.85 - (i * 0.06)
		spine.mesh = sm
		spine.material_override = bone_mat
		spine.position = Vector3(0, 1.8 + i * 1.3, -0.9 + (i * 0.1))
		spine.rotation_degrees.x = 45
		mesh_node.add_child(spine)
		
	# 4. Six Ventral Suction Nodules (along the inner curve)
	for i in range(6):
		var sucker = MeshInstance3D.new()
		var sum = CylinderMesh.new()
		sum.top_radius = 0.22 - (i * 0.02)
		sum.bottom_radius = 0.24 - (i * 0.02)
		sum.height = 0.12
		sucker.mesh = sum
		sucker.material_override = sucker_mat
		sucker.position = Vector3(0, 1.5 + i * 1.35, 1.1 + (i * 0.1))
		sucker.rotation_degrees.x = -85
		mesh_node.add_child(sucker)
		
	# 5. Apex Glowing Abyssal Eye / Stinger
	var eye = MeshInstance3D.new()
	var em = SphereMesh.new()
	em.radius = 0.55
	em.height = 0.75
	eye.mesh = em
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.05, 0.05)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.05, 0.05)
	eye_mat.emission_energy_multiplier = 3.5
	eye.material_override = eye_mat
	eye.position = Vector3(0, 10.2, 0.5)
	mesh_node.add_child(eye)

func _physics_process(delta):
	var mn = get_meta("mesh_node") if has_meta("mesh_node") else null
	var is_tweening = false
	if has_meta("attack_tween"):
		var tw = get_meta("attack_tween")
		if is_instance_valid(tw) and tw.is_running():
			is_tweening = true
			
	# Idle serpentine sway when not executing attack slam
	if mn and not is_tweening:
		var t = Time.get_ticks_msec() * 0.003
		mn.rotation_degrees.x = sin(t) * 12.0
		mn.rotation_degrees.z = cos(t * 0.8) * 8.0
		
	var target_is_dead = false
	if current_target != null:
		var target_hc = current_target.get_node_or_null("HealthComponent")
		if (target_hc and target_hc.is_dead) or not current_target.is_in_group("Targetable"):
			target_is_dead = true
			
	if current_target == null or not is_instance_valid(current_target) or target_is_dead:
		find_new_target()
		
	if current_target != null:
		# Swivel towards current target on Y axis so slap tracks enemies accurately
		var to_target = current_target.global_position - global_position
		to_target.y = 0
		if to_target.length() > 0.1:
			var target_angle = atan2(to_target.x, to_target.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 6.0 * delta)
			
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = attack_range
		if "Base" in current_target.name: effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name: effective_range += 2.5
		
		if dist <= effective_range:
			attack_timer += delta
			if attack_timer >= attack_rate:
				attack_timer = 0.0
				execute_tentacle_slam()
		else:
			current_target = null

func execute_tentacle_slam():
	if current_target == null or not is_instance_valid(current_target): return
	var target_ref = current_target
	var hp = target_ref.get_node_or_null("HealthComponent")
	if hp: hp.take_damage(damage)
	
	# Whip slam animation
	var mn = get_meta("mesh_node") if has_meta("mesh_node") else null
	if mn:
		if has_meta("attack_tween"):
			var old_tw = get_meta("attack_tween")
			if is_instance_valid(old_tw) and old_tw.is_valid():
				old_tw.kill()
		var tw = create_tween()
		set_meta("attack_tween", tw)
		# Wind back slightly, then violently slam forward down
		tw.tween_property(mn, "rotation_degrees:x", -18.0, 0.12)
		tw.tween_property(mn, "rotation_degrees:x", 68.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(mn, "rotation_degrees:x", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	# Ground impact shockwave effect at target location
	var shock = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 0.5
	tm.outer_radius = 1.4
	shock.mesh = tm
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.6, 0.1, 0.7, 0.8)
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.emission_enabled = true
	s_mat.emission = Color(0.6, 0.1, 0.7)
	s_mat.emission_energy_multiplier = 2.0
	shock.material_override = s_mat
	get_tree().current_scene.add_child(shock)
	shock.global_position = target_ref.global_position + Vector3(0, 0.1, 0)
	var stw = shock.create_tween()
	stw.tween_property(shock, "scale", Vector3(2.5, 1.0, 2.5), 0.3)
	stw.parallel().tween_property(s_mat, "albedo_color:a", 0.0, 0.3)
	stw.tween_callback(shock.queue_free)

func find_new_target():
	current_target = null
	var enemies = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if not node.is_in_group("Beast") and is_instance_valid(node) and node != self:
			enemies.append(node)
	
	var closest = 99999.0
	for e in enemies:
		if is_instance_valid(e):
			var hc = e.get_node_or_null("HealthComponent")
			if hc and hc.is_dead: continue
			if GameState.is_unit_stealthed_from(e, self): continue
			var d = global_position.distance_to(e.global_position)
			var effective_range = attack_range + 0.5
			if "Base" in e.name: effective_range += 5.5
			elif "Tower" in e.name or "CommandBay" in e.name: effective_range += 2.5
			
			if d < effective_range and d < closest:
				closest = d
				current_target = e
