extends Node
class_name HumanoidRig

func _init():
	name = "HumanoidRig"

# Reference to the unit CharacterBody3D
var unit: CharacterBody3D = null
var rig_root: Node3D = null

# Anatomical Rig Nodes
var torso: Node3D = null
var head: Node3D = null
var left_arm_pivot: Node3D = null
var left_arm_mesh: Node3D = null
var right_arm_pivot: Node3D = null
var right_arm_mesh: Node3D = null
var left_leg_pivot: Node3D = null
var left_leg_mesh: Node3D = null
var right_leg_pivot: Node3D = null
var right_leg_mesh: Node3D = null
var weapon_node: Node3D = null

# Base resting positions
var base_torso_pos: Vector3 = Vector3(0, 0.95, 0)
var base_head_pos: Vector3 = Vector3(0, 1.55, 0)
var base_left_arm_pos: Vector3 = Vector3(-0.32, 1.28, 0)
var base_right_arm_pos: Vector3 = Vector3(0.32, 1.28, 0)
var base_left_leg_pos: Vector3 = Vector3(-0.16, 0.62, 0)
var base_right_leg_pos: Vector3 = Vector3(0.16, 0.62, 0)

# Animation timers & state
var walk_time: float = 0.0
var idle_time: float = 0.0
var limp_time: float = 0.0
var is_active: bool = false

func setup(p_unit: CharacterBody3D):
	unit = p_unit
	if not unit: return
	
	# Hide or remove any existing raw placeholder meshes in the unit visual root
	var visual_root = unit.get_node_or_null("VisualPivot")
	if not visual_root: visual_root = unit.get_node_or_null("MeshInstance3D")
	if not visual_root: visual_root = unit.get_node_or_null("Visuals")
	if not visual_root:
		visual_root = Node3D.new()
		visual_root.name = "VisualPivot"
		unit.add_child(visual_root)
		
	# Hide previous raw mesh if it exists
	if visual_root is MeshInstance3D:
		visual_root.mesh = null
	for child in visual_root.get_children():
		if child.name == "HumanoidRigRoot":
			child.queue_free()
		elif child.name.begins_with("@MeshInstance3D") or child.name in ["LeftArm", "RightArm", "LeftLeg", "RightLeg", "Cosmetic_Helm", "Cosmetic_Spartan"]:
			child.visible = false
			
	_build_humanoid_anatomy(visual_root)
	is_active = true

func _build_humanoid_anatomy(parent: Node3D):
	rig_root = Node3D.new()
	rig_root.name = "HumanoidRigRoot"
	parent.add_child(rig_root)
	
	# Determine Faction & Styling
	var u_name = unit.name
	var is_reach = "Reach" in u_name
	var is_scrap = "Scrap" in u_name
	var is_rimworlder = "Rimworlder" in u_name
	var is_medic = "Medic" in u_name or "Repair" in u_name
	var is_commander = "Commander" in u_name or "Hero" in u_name
	var is_sniper = "Sniper" in u_name or "Ranged" in u_name
	var is_rocket = "Rocket" in u_name
	var is_hunter = "Hunter" in u_name or "Assassin" in u_name
	
	# Materials
	var body_mat = StandardMaterial3D.new()
	var armor_mat = StandardMaterial3D.new()
	var visor_mat = StandardMaterial3D.new()
	var weapon_mat = StandardMaterial3D.new()
	
	if is_reach:
		# Sleek cybernetic white with glowing cyan energy
		body_mat.albedo_color = Color(0.92, 0.95, 0.98)
		body_mat.metallic = 0.8
		body_mat.roughness = 0.2
		armor_mat.albedo_color = Color(0.82, 0.88, 0.94)
		armor_mat.metallic = 0.9
		armor_mat.roughness = 0.15
		visor_mat.albedo_color = Color(0.0, 0.9, 1.0)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.0, 0.9, 1.0)
		visor_mat.emission_energy_multiplier = 3.5
		weapon_mat.albedo_color = Color(0.2, 0.25, 0.3)
		weapon_mat.metallic = 0.9
	elif is_scrap:
		# Weathered rust iron and junk metal
		body_mat.albedo_color = Color(0.46, 0.26, 0.16)
		body_mat.roughness = 0.85
		armor_mat.albedo_color = Color(0.32, 0.3, 0.28)
		armor_mat.metallic = 0.6
		armor_mat.roughness = 0.7
		visor_mat.albedo_color = Color(1.0, 0.35, 0.1)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(1.0, 0.35, 0.1)
		visor_mat.emission_energy_multiplier = 2.0
		weapon_mat.albedo_color = Color(0.28, 0.25, 0.22)
		weapon_mat.metallic = 0.7
	elif is_rimworlder:
		# Leather duster / survival khaki
		body_mat.albedo_color = Color(0.45, 0.32, 0.22)
		body_mat.roughness = 0.8
		armor_mat.albedo_color = Color(0.55, 0.48, 0.36)
		armor_mat.roughness = 0.75
		visor_mat.albedo_color = Color(0.15, 0.15, 0.15)
		weapon_mat.albedo_color = Color(0.25, 0.22, 0.2)
		weapon_mat.metallic = 0.5
	elif is_medic:
		# Medical white with red cross
		body_mat.albedo_color = Color(0.9, 0.9, 0.92)
		body_mat.roughness = 0.5
		armor_mat.albedo_color = Color(0.85, 0.15, 0.15)
		visor_mat.albedo_color = Color(0.1, 0.8, 0.3)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.1, 0.8, 0.3)
		visor_mat.emission_energy_multiplier = 2.0
		weapon_mat.albedo_color = Color(0.3, 0.3, 0.3)
	elif is_hunter or "Assassin" in u_name:
		# Stealth midnight charcoal / purple visor
		body_mat.albedo_color = Color(0.12, 0.12, 0.14)
		body_mat.roughness = 0.6
		armor_mat.albedo_color = Color(0.18, 0.18, 0.22)
		visor_mat.albedo_color = Color(0.75, 0.15, 0.9)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.75, 0.15, 0.9)
		visor_mat.emission_energy_multiplier = 3.0
		weapon_mat.albedo_color = Color(0.1, 0.1, 0.12)
		weapon_mat.metallic = 0.9
	elif is_commander:
		# Majestic heavy slate plate with gold trim
		body_mat.albedo_color = Color(0.18, 0.22, 0.28)
		body_mat.metallic = 0.7
		armor_mat.albedo_color = Color(0.95, 0.78, 0.2)
		armor_mat.metallic = 0.9
		armor_mat.roughness = 0.2
		visor_mat.albedo_color = Color(1.0, 0.85, 0.3)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(1.0, 0.85, 0.3)
		visor_mat.emission_energy_multiplier = 2.5
		weapon_mat.albedo_color = Color(0.9, 0.8, 0.2)
		weapon_mat.metallic = 0.95
	else:
		# Standard Dominion military combat uniform (olive drab / slate)
		body_mat.albedo_color = Color(0.24, 0.34, 0.2)
		body_mat.roughness = 0.7
		armor_mat.albedo_color = Color(0.18, 0.24, 0.16)
		armor_mat.metallic = 0.4
		visor_mat.albedo_color = Color(0.2, 0.7, 0.9)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.2, 0.7, 0.9)
		visor_mat.emission_energy_multiplier = 2.0
		weapon_mat.albedo_color = Color(0.18, 0.18, 0.18)
		weapon_mat.metallic = 0.8

	# --- 1. TORSO & CHEST ---
	torso = Node3D.new()
	torso.name = "Torso"
	torso.position = base_torso_pos
	rig_root.add_child(torso)
	
	var chest_mesh = MeshInstance3D.new()
	var box_t = BoxMesh.new()
	box_t.size = Vector3(0.48, 0.65, 0.28)
	chest_mesh.mesh = box_t
	chest_mesh.material_override = body_mat
	torso.add_child(chest_mesh)
	
	# Armor vest plate
	var armor_plate = MeshInstance3D.new()
	var box_ap = BoxMesh.new()
	box_ap.size = Vector3(0.52, 0.45, 0.32)
	armor_plate.mesh = box_ap
	armor_plate.material_override = armor_mat
	armor_plate.position = Vector3(0, 0.08, 0)
	torso.add_child(armor_plate)
	
	# Tactical belt
	var belt = MeshInstance3D.new()
	var box_b = BoxMesh.new()
	box_b.size = Vector3(0.5, 0.12, 0.3)
	belt.mesh = box_b
	belt.material_override = weapon_mat
	belt.position = Vector3(0, -0.28, 0)
	torso.add_child(belt)

	# --- 2. HEAD & HELMET ---
	head = Node3D.new()
	head.name = "Head"
	head.position = base_head_pos
	rig_root.add_child(head)
	
	var head_mesh = MeshInstance3D.new()
	var sphere_h = SphereMesh.new()
	sphere_h.radius = 0.2
	sphere_h.height = 0.38
	head_mesh.mesh = sphere_h
	head_mesh.material_override = body_mat
	head.add_child(head_mesh)
	
	# Helmet / Cowl
	var helm_mesh = MeshInstance3D.new()
	var sphere_helm = SphereMesh.new()
	sphere_helm.radius = 0.23
	sphere_helm.height = 0.4
	helm_mesh.mesh = sphere_helm
	helm_mesh.material_override = armor_mat
	helm_mesh.position = Vector3(0, 0.04, -0.02)
	head.add_child(helm_mesh)
	
	# Eye Visor / Face Guard
	var visor_mesh = MeshInstance3D.new()
	var box_v = BoxMesh.new()
	box_v.size = Vector3(0.24, 0.08, 0.14)
	visor_mesh.mesh = box_v
	visor_mesh.material_override = visor_mat
	visor_mesh.position = Vector3(0, 0.02, 0.16)
	head.add_child(visor_mesh)

	# --- 3. LEFT ARM (SHOULDER PIVOT) ---
	left_arm_pivot = Node3D.new()
	left_arm_pivot.name = "LeftArmPivot"
	left_arm_pivot.position = base_left_arm_pos
	rig_root.add_child(left_arm_pivot)
	
	left_arm_mesh = MeshInstance3D.new()
	var cyl_la = CapsuleMesh.new()
	cyl_la.radius = 0.09
	cyl_la.height = 0.55
	left_arm_mesh.mesh = cyl_la
	left_arm_mesh.material_override = body_mat
	left_arm_mesh.position = Vector3(0, -0.25, 0)
	left_arm_pivot.add_child(left_arm_mesh)
	
	# Shoulder pauldron
	var left_pad = MeshInstance3D.new()
	var box_lp = BoxMesh.new()
	box_lp.size = Vector3(0.18, 0.16, 0.2)
	left_pad.mesh = box_lp
	left_pad.material_override = armor_mat
	left_pad.position = Vector3(0, 0.04, 0)
	left_arm_pivot.add_child(left_pad)

	# --- 4. RIGHT ARM (SHOULDER PIVOT & WEAPON) ---
	right_arm_pivot = Node3D.new()
	right_arm_pivot.name = "RightArmPivot"
	right_arm_pivot.position = base_right_arm_pos
	rig_root.add_child(right_arm_pivot)
	
	right_arm_mesh = MeshInstance3D.new()
	var cyl_ra = CapsuleMesh.new()
	cyl_ra.radius = 0.09
	cyl_ra.height = 0.55
	right_arm_mesh.mesh = cyl_ra
	right_arm_mesh.material_override = body_mat
	right_arm_mesh.position = Vector3(0, -0.25, 0)
	right_arm_pivot.add_child(right_arm_mesh)
	
	# Shoulder pauldron
	var right_pad = MeshInstance3D.new()
	var box_rp = BoxMesh.new()
	box_rp.size = Vector3(0.18, 0.16, 0.2)
	right_pad.mesh = box_rp
	right_pad.material_override = armor_mat
	right_pad.position = Vector3(0, 0.04, 0)
	right_arm_pivot.add_child(right_pad)
	
	# --- WEAPON IN HAND ---
	weapon_node = Node3D.new()
	weapon_node.name = "EquippedWeapon"
	weapon_node.position = Vector3(0, -0.45, 0.18)
	right_arm_pivot.add_child(weapon_node)
	
	_build_weapon(weapon_node, u_name, weapon_mat, visor_mat)

	# --- 5. LEFT LEG (HIP PIVOT & BOOT) ---
	left_leg_pivot = Node3D.new()
	left_leg_pivot.name = "LeftLegPivot"
	left_leg_pivot.position = base_left_leg_pos
	rig_root.add_child(left_leg_pivot)
	
	left_leg_mesh = MeshInstance3D.new()
	var cyl_ll = CapsuleMesh.new()
	cyl_ll.radius = 0.1
	cyl_ll.height = 0.6
	left_leg_mesh.mesh = cyl_ll
	left_leg_mesh.material_override = body_mat
	left_leg_mesh.position = Vector3(0, -0.28, 0)
	left_leg_pivot.add_child(left_leg_mesh)
	
	# Left Boot
	var left_boot = MeshInstance3D.new()
	var box_lb = BoxMesh.new()
	box_lb.size = Vector3(0.18, 0.16, 0.28)
	left_boot.mesh = box_lb
	left_boot.material_override = weapon_mat
	left_boot.position = Vector3(0, -0.52, 0.05)
	left_leg_pivot.add_child(left_boot)

	# --- 6. RIGHT LEG (HIP PIVOT & BOOT) ---
	right_leg_pivot = Node3D.new()
	right_leg_pivot.name = "RightLegPivot"
	right_leg_pivot.position = base_right_leg_pos
	rig_root.add_child(right_leg_pivot)
	
	right_leg_mesh = MeshInstance3D.new()
	var cyl_rl = CapsuleMesh.new()
	cyl_rl.radius = 0.1
	cyl_rl.height = 0.6
	right_leg_mesh.mesh = cyl_rl
	right_leg_mesh.material_override = body_mat
	right_leg_mesh.position = Vector3(0, -0.28, 0)
	right_leg_pivot.add_child(right_leg_mesh)
	
	# Right Boot
	var right_boot = MeshInstance3D.new()
	var box_rb = BoxMesh.new()
	box_rb.size = Vector3(0.18, 0.16, 0.28)
	right_boot.mesh = box_rb
	right_boot.material_override = weapon_mat
	right_boot.position = Vector3(0, -0.52, 0.05)
	right_leg_pivot.add_child(right_boot)

func _build_weapon(w_root: Node3D, u_name: String, w_mat: Material, energy_mat: Material):
	var w_mesh = MeshInstance3D.new()
	
	if "Sniper" in u_name or "ReachRanged" in u_name or "ScrapRanged" in u_name:
		# Long-barreled sniper rifle with scope
		var rifle_body = BoxMesh.new()
		rifle_body.size = Vector3(0.08, 0.12, 1.1)
		w_mesh.mesh = rifle_body
		w_mesh.material_override = w_mat
		w_mesh.position = Vector3(0, 0, 0.25)
		w_root.add_child(w_mesh)
		
		var scope = MeshInstance3D.new()
		var cyl_s = CylinderMesh.new()
		cyl_s.top_radius = 0.035
		cyl_s.bottom_radius = 0.035
		cyl_s.height = 0.35
		scope.mesh = cyl_s
		scope.rotation.x = deg_to_rad(90.0)
		scope.position = Vector3(0, 0.1, 0.1)
		scope.material_override = energy_mat
		w_root.add_child(scope)
	elif "Rocket" in u_name:
		# Shoulder rocket tube
		var tube = CylinderMesh.new()
		tube.top_radius = 0.12
		tube.bottom_radius = 0.12
		tube.height = 1.2
		w_mesh.mesh = tube
		w_mesh.material_override = w_mat
		w_mesh.rotation.x = deg_to_rad(90.0)
		w_mesh.position = Vector3(0.1, 0.3, 0.1)
		w_root.add_child(w_mesh)
	elif "Medic" in u_name or "Repair" in u_name:
		# Medical Injector or Wrench
		var tool_box = BoxMesh.new()
		tool_box.size = Vector3(0.1, 0.18, 0.45)
		w_mesh.mesh = tool_box
		w_mesh.material_override = w_mat
		w_root.add_child(w_mesh)
		
		var tip = MeshInstance3D.new()
		var tip_mesh = CylinderMesh.new()
		tip_mesh.top_radius = 0.02
		tip_mesh.bottom_radius = 0.05
		tip_mesh.height = 0.25
		tip.mesh = tip_mesh
		tip.rotation.x = deg_to_rad(90.0)
		tip.position = Vector3(0, 0, 0.3)
		tip.material_override = energy_mat
		w_root.add_child(tip)
	elif "Melee" in u_name or "Commander" in u_name or "Hero" in u_name:
		# Sword / Combat Blade
		var blade = BoxMesh.new()
		blade.size = Vector3(0.04, 0.14, 0.95)
		w_mesh.mesh = blade
		w_mesh.material_override = energy_mat
		w_mesh.position = Vector3(0, 0, 0.35)
		w_root.add_child(w_mesh)
		
		var hilt = MeshInstance3D.new()
		var hilt_mesh = BoxMesh.new()
		hilt_mesh.size = Vector3(0.08, 0.28, 0.06)
		hilt.mesh = hilt_mesh
		hilt.material_override = w_mat
		hilt.position = Vector3(0, 0, -0.1)
		w_root.add_child(hilt)
	elif "Hunter" in u_name or "Assassin" in u_name:
		# Combat daggers
		var dagger = BoxMesh.new()
		dagger.size = Vector3(0.04, 0.08, 0.55)
		w_mesh.mesh = dagger
		w_mesh.material_override = energy_mat
		w_mesh.position = Vector3(0, 0, 0.2)
		w_root.add_child(w_mesh)
	else:
		# Combat Assault Rifle / Carbine
		var gun = BoxMesh.new()
		gun.size = Vector3(0.08, 0.12, 0.65)
		w_mesh.mesh = gun
		w_mesh.material_override = w_mat
		w_mesh.position = Vector3(0, 0, 0.15)
		w_root.add_child(w_mesh)
		
		var barrel = MeshInstance3D.new()
		var bar_mesh = CylinderMesh.new()
		bar_mesh.top_radius = 0.025
		bar_mesh.bottom_radius = 0.025
		bar_mesh.height = 0.3
		barrel.mesh = bar_mesh
		barrel.rotation.x = deg_to_rad(90.0)
		barrel.position = Vector3(0, 0.02, 0.5)
		barrel.material_override = w_mat
		w_root.add_child(barrel)

func animate(delta: float, is_moving: bool, is_critically_wounded: bool, move_speed: float):
	if not is_active or not torso: return
	
	if is_critically_wounded:
		# --- CRITICALLY WOUNDED ANATOMY STATE ---
		# Hunched forward in agony
		torso.rotation.x = deg_to_rad(24.0)
		head.rotation.x = deg_to_rad(18.0)
		
		# Left arm tightly clutching torso wound across the abdomen
		left_arm_pivot.rotation.z = deg_to_rad(45.0)
		left_arm_pivot.rotation.x = deg_to_rad(22.0)
		left_arm_pivot.rotation.y = deg_to_rad(25.0)
		
		# Right arm lower, struggling with weapon
		right_arm_pivot.rotation.x = deg_to_rad(-12.0)
		right_arm_pivot.rotation.y = deg_to_rad(-8.0)
		
		if is_moving:
			# Limping hobble gait: asymmetric dragging stride
			limp_time += delta * clamp(move_speed * 1.4, 2.0, 4.2)
			
			# Left leg drags forward heavily
			left_leg_pivot.rotation.x = sin(limp_time) * 0.52
			# Right leg hitches short and stiff
			right_leg_pivot.rotation.x = -sin(limp_time) * 0.26 + 0.12
			
			# Severe lateral limp lurch
			torso.rotation.z = sin(limp_time) * 0.14
			torso.position.y = base_torso_pos.y - 0.06 + abs(sin(limp_time)) * 0.04
			head.position.y = base_head_pos.y - 0.08 + abs(sin(limp_time)) * 0.03
		else:
			# Standing wounded: heavy pained breathing shudder
			idle_time += delta * 3.2
			torso.rotation.z = lerp(torso.rotation.z, 0.0, 8.0 * delta)
			torso.position.y = base_torso_pos.y + sin(idle_time) * 0.025
			head.position.y = base_head_pos.y + sin(idle_time) * 0.015
			left_leg_pivot.rotation = Vector3.ZERO
			right_leg_pivot.rotation = Vector3.ZERO
	else:
		# --- HEALTHY / NORMAL STATE ---
		torso.rotation.x = lerp(torso.rotation.x, 0.0, 10.0 * delta)
		head.rotation.x = lerp(head.rotation.x, 0.0, 10.0 * delta)
		
		if is_moving:
			# Authentic alternating two-legged stride
			walk_time += delta * clamp(move_speed * 2.2, 3.5, 9.0)
			
			# Leg stride (left vs right alternating)
			left_leg_pivot.rotation.x = sin(walk_time) * 0.65
			right_leg_pivot.rotation.x = -sin(walk_time) * 0.65
			left_leg_pivot.rotation.z = 0.0
			right_leg_pivot.rotation.z = 0.0
			
			# Arm swing opposite legs: left arm swings with right leg
			left_arm_pivot.rotation.x = -sin(walk_time) * 0.55
			left_arm_pivot.rotation.z = deg_to_rad(-6.0)
			left_arm_pivot.rotation.y = 0.0
			
			# Right arm swings while holding weapon ready forward
			right_arm_pivot.rotation.x = deg_to_rad(-22.0) + sin(walk_time) * 0.32
			right_arm_pivot.rotation.y = deg_to_rad(-10.0)
			right_arm_pivot.rotation.z = 0.0
			
			# Torso bounce / vertical bob & sway
			torso.position.y = base_torso_pos.y + abs(sin(walk_time)) * 0.07
			torso.rotation.z = sin(walk_time) * 0.04
			head.position.y = base_head_pos.y + abs(sin(walk_time)) * 0.03
		else:
			# Standing pose: natural resting breathing stance with weapon at ready
			idle_time += delta * 2.2
			walk_time = 0.0
			
			# Gentle breathing cycle
			torso.position.y = base_torso_pos.y + sin(idle_time) * 0.022
			torso.rotation.z = lerp(torso.rotation.z, 0.0, 8.0 * delta)
			head.position.y = base_head_pos.y + sin(idle_time) * 0.014
			
			# Arms in ready standing posture
			right_arm_pivot.rotation.x = lerp(right_arm_pivot.rotation.x, deg_to_rad(-24.0), 8.0 * delta)
			right_arm_pivot.rotation.y = lerp(right_arm_pivot.rotation.y, deg_to_rad(-12.0), 8.0 * delta)
			right_arm_pivot.rotation.z = lerp(right_arm_pivot.rotation.z, 0.0, 8.0 * delta)
			
			left_arm_pivot.rotation.x = lerp(left_arm_pivot.rotation.x, deg_to_rad(4.0), 8.0 * delta)
			left_arm_pivot.rotation.z = lerp(left_arm_pivot.rotation.z, deg_to_rad(-8.0), 8.0 * delta)
			left_arm_pivot.rotation.y = lerp(left_arm_pivot.rotation.y, 0.0, 8.0 * delta)
			
			# Stable standing stance
			left_leg_pivot.rotation.x = lerp(left_leg_pivot.rotation.x, 0.0, 8.0 * delta)
			right_leg_pivot.rotation.x = lerp(right_leg_pivot.rotation.x, 0.0, 8.0 * delta)
			left_leg_pivot.rotation.z = deg_to_rad(2.5)
			right_leg_pivot.rotation.z = deg_to_rad(-2.5)
