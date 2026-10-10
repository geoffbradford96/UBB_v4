extends StaticBody3D

var faction: String = "Dominion"

@export var unit_attribute: String = "Mechanical"

# This allows you to drag and drop the Projectile.tscn into the inspector
@export var projectile_scene: PackedScene 
@export var team: String = "SideB"

var current_target: Node3D = null
var fire_rate = 1.0 # shoots once every second
var fire_timer = 0.0
var enemy_team: String = "SideA"

func _ready():
	add_to_group("Targetable")
	if is_in_group("SideA"): remove_from_group("SideA")
	if is_in_group("SideB"): remove_from_group("SideB")
	add_to_group(team)
	if team == "SideA":
		enemy_team = "SideB"
	else:
		enemy_team = "SideA"
		
	# Connect death signal to update the Comeback Mechanic
	var health = get_node_or_null("HealthComponent")
	if health:
		health.connect("died", Callable(self, "_on_tower_destroyed"))
		
	# Check for units already spawned inside detection area
	await get_tree().process_frame
	var det = get_node_or_null("DetectionArea")
	if det and is_instance_valid(det):
		for b in det.get_overlapping_bodies():
			_on_detection_area_body_entered(b)

func _on_tower_destroyed():
	# If this is a Player tower, tell the ArenaManager to speed up Requisition!
	if team == "SideA":
		var manager = get_tree().current_scene
		if manager.has_method("tower_lost"):
			manager.tower_lost()

var targets_in_range: Array = []

func _process(delta):
	# Clean up dead targets from our array
	targets_in_range = targets_in_range.filter(func(t):
		if not is_instance_valid(t): return false
		var hc = t.get_node_or_null("HealthComponent")
		if hc and hc.is_dead: return false
		return t.is_in_group("Targetable")
	)
	
	if current_target != null:
		var curr_hc = current_target.get_node_or_null("HealthComponent")
		if (curr_hc and curr_hc.is_dead) or not current_target.is_in_group("Targetable"):
			targets_in_range.erase(current_target)
			current_target = null
			
	if current_target == null or not is_instance_valid(current_target):
		if targets_in_range.size() > 0:
			current_target = targets_in_range[0]
		else:
			current_target = null
			
	if current_target != null:
		var f_mesh = get_meta("faction_mesh") if has_meta("faction_mesh") else null
		if f_mesh and is_instance_valid(f_mesh):
			if f_mesh.has_meta("dominion_turret"):
				var turret = f_mesh.get_meta("dominion_turret")
				if is_instance_valid(turret):
					var dir = (current_target.global_position - turret.global_position).normalized()
					var ang = atan2(dir.x, dir.z) - global_rotation.y
					turret.rotation.y = lerp_angle(turret.rotation.y, ang, 8.0 * delta)
		
		fire_timer += delta
		if fire_timer >= fire_rate:
			fire_timer = 0.0
			shoot_at_target()

func shoot_at_target():
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + Vector3(0, 6, 0) 
		proj.target = current_target
		proj.set("damage", 25.0)
		proj.set("speed", 25.0)
		
		# Turret firing recoil kick
		var f_mesh = get_meta("faction_mesh") if has_meta("faction_mesh") else null
		if f_mesh and is_instance_valid(f_mesh):
			if f_mesh.has_meta("dominion_turret"):
				var turret = f_mesh.get_meta("dominion_turret")
				if is_instance_valid(turret):
					var tw = create_tween()
					tw.tween_property(turret, "position:z", -0.3, 0.06)
					tw.tween_property(turret, "position:z", 0.0, 0.15)
		
		var mesh = proj.get_node_or_null("MeshInstance3D")
		if mesh and mesh.mesh:
			var mat = StandardMaterial3D.new()
			var laser_color = Color(0.2, 1.0, 0.2)
			if faction == "Void": laser_color = Color(0.85, 0.1, 0.85)
			elif faction == "The Reach": laser_color = Color(0.0, 0.85, 1.0)
			elif faction == "Dominion": laser_color = Color(1.0, 0.65, 0.1)
			elif faction == "Pirates": laser_color = Color(1.0, 0.45, 0.1)
			elif faction == "Rimworlders": laser_color = Color(1.0, 0.35, 0.05)
			mat.albedo_color = laser_color
			mat.emission_enabled = true
			mat.emission = laser_color
			mat.emission_energy_multiplier = 3.0
			mesh.set_surface_override_material(0, mat)

func _on_detection_area_body_entered(body):
	if body.is_in_group("Targetable") and not body.is_in_group(team):
		if not targets_in_range.has(body):
			targets_in_range.append(body)

func _on_detection_area_body_exited(body):
	if targets_in_range.has(body):
		targets_in_range.erase(body)
	if body == current_target:
		current_target = null




