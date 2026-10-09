extends CharacterBody3D

@export var unit_attribute: String = "Mechanical"

@export var damage: float = 5.0
@export var attack_range: float = 10.0
@export var attack_rate: float = 1.0

var current_target: Node3D = null
var attack_timer: float = 0.0

var projectile_scene = preload("res://Scenes/Projectile.tscn")

func _ready():
	add_to_group("Targetable")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
		
	velocity.x = 0
	velocity.z = 0
	move_and_slide()
	
	if not "target_recheck_timer" in self:
		set_meta("target_recheck", 1.0)
	var __target_timer = get_meta("target_recheck") if has_meta("target_recheck") else 1.0
	__target_timer -= delta
	set_meta("target_recheck", __target_timer)
	
	if current_target == null or not is_instance_valid(current_target) or __target_timer <= 0.0:
		if __target_timer <= 0.0: set_meta("target_recheck", 1.0)
		find_new_target()
		
	if current_target != null:
		var dist = global_position.distance_to(current_target.global_position)
		var effective_range = attack_range
		if "Base" in current_target.name:
			effective_range += 5.5
		elif "Tower" in current_target.name or "CommandBay" in current_target.name:
			effective_range += 2.5
			
		if dist <= effective_range:
			attack_timer += delta
			if attack_timer >= attack_rate:
				attack_timer = 0.0
				shoot()
		else:
			current_target = null

func shoot():
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + Vector3(0, 1.5, 0)
		proj.target = current_target
		proj.set("damage", damage)
		proj.set("speed", 15.0)
		
		var mesh = proj.get_node_or_null("MeshInstance3D")
		if mesh and mesh.mesh:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.8, 0.2, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.2, 1.0)
			mat.emission_energy_multiplier = 2.0
			mesh.set_surface_override_material(0, mat)

func find_new_target():
	current_target = null
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
	var enemies = []
	if my_team != "":
		for node in get_tree().get_nodes_in_group("Targetable"):
			if not node.is_in_group(my_team) and is_instance_valid(node) and node != self:
				enemies.append(node)
	var closest = 99999.0
	for e in enemies:
		if is_instance_valid(e):
			var d = global_position.distance_to(e.global_position)
			var effective_range = attack_range + 0.5
			if "Base" in e.name:
				effective_range += 5.5
			elif "Tower" in e.name or "CommandBay" in e.name:
				effective_range += 2.5
				
			if d < effective_range and d < closest:
				closest = d
				current_target = e
