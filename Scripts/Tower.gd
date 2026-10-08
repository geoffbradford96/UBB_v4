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

func _on_tower_destroyed():
	# If this is a Player tower, tell the ArenaManager to speed up Requisition!
	if team == "SideA":
		var manager = get_tree().current_scene
		if manager.has_method("tower_lost"):
			manager.tower_lost()

var targets_in_range: Array = []

func _process(delta):
	# Clean up dead targets from our array
	targets_in_range = targets_in_range.filter(func(t): return is_instance_valid(t))
	
	if current_target == null or not is_instance_valid(current_target):
		if targets_in_range.size() > 0:
			current_target = targets_in_range[0]
		else:
			current_target = null
			
	if current_target != null:
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
		
		var mesh = proj.get_node_or_null("MeshInstance3D")
		if mesh and mesh.mesh:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.2, 1.0, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(0.2, 1.0, 0.2)
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




