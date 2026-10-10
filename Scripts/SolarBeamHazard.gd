extends Node3D
class_name SolarBeamHazard

signal beam_finished

@export var beam_radius: float = 5.2
@export var move_speed: float = 6.0
@export var tick_interval: float = 0.25
@export var damage_per_tick: float = 5.0 # ~20 DPS

var duration: float = 30.0
var life_time: float = 0.0
var is_fading: bool = false
var fade_progress: float = 0.0

var wander_target: Vector3 = Vector3.ZERO
var target_change_timer: float = 0.0
var damage_timer: float = 0.0

var area: Area3D
var inner_mesh: MeshInstance3D
var outer_mesh: MeshInstance3D
var ground_ring: MeshInstance3D
var light: OmniLight3D

func _ready():
	_setup_visuals()
	_setup_collision()
	_pick_new_wander_target()

func setup_duration(active_sec: float):
	duration = active_sec

func _setup_visuals():
	# Ground scorch ring
	ground_ring = MeshInstance3D.new()
	var ring_cyl = CylinderMesh.new()
	ring_cyl.top_radius = beam_radius
	ring_cyl.bottom_radius = beam_radius * 1.05
	ring_cyl.height = 0.06
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.45, 0.05, 0.7)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.6, 0.1)
	ring_mat.emission_energy_multiplier = 3.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ground_ring.mesh = ring_cyl
	ground_ring.material_override = ring_mat
	ground_ring.position.y = 0.05
	add_child(ground_ring)
	
	# Core vertical beam
	inner_mesh = MeshInstance3D.new()
	var inner_cyl = CylinderMesh.new()
	inner_cyl.top_radius = beam_radius * 0.75
	inner_cyl.bottom_radius = beam_radius * 0.85
	inner_cyl.height = 80.0
	var inner_mat = StandardMaterial3D.new()
	inner_mat.albedo_color = Color(1.0, 0.98, 0.7, 0.85)
	inner_mat.emission_enabled = true
	inner_mat.emission = Color(1.0, 0.95, 0.6)
	inner_mat.emission_energy_multiplier = 4.5
	inner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	inner_mesh.mesh = inner_cyl
	inner_mesh.material_override = inner_mat
	inner_mesh.position.y = 40.0
	add_child(inner_mesh)
	
	# Corona outer aura
	outer_mesh = MeshInstance3D.new()
	var outer_cyl = CylinderMesh.new()
	outer_cyl.top_radius = beam_radius * 1.05
	outer_cyl.bottom_radius = beam_radius * 1.15
	outer_cyl.height = 80.0
	var outer_mat = StandardMaterial3D.new()
	outer_mat.albedo_color = Color(1.0, 0.4, 0.05, 0.35)
	outer_mat.emission_enabled = true
	outer_mat.emission = Color(1.0, 0.35, 0.0)
	outer_mat.emission_energy_multiplier = 2.0
	outer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outer_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	outer_mesh.mesh = outer_cyl
	outer_mesh.material_override = outer_mat
	outer_mesh.position.y = 40.0
	add_child(outer_mesh)
	
	# Point light on ground
	light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.3)
	light.light_energy = 4.0
	light.omni_range = beam_radius * 2.5
	light.position.y = 2.0
	add_child(light)

func _setup_collision():
	area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1 | 2 # Detect all units/targets
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = beam_radius
	cyl.height = 60.0
	col.shape = cyl
	col.position.y = 30.0
	area.add_child(col)
	add_child(area)

func _pick_new_wander_target():
	# Wander across the playable arena boundaries
	wander_target = Vector3(
		randf_range(-70.0, 70.0),
		0.0,
		randf_range(-70.0, 70.0)
	)
	target_change_timer = randf_range(4.0, 8.0)

func _physics_process(delta):
	life_time += delta
	
	# Check if duration finished
	if not is_fading and life_time >= duration:
		is_fading = true
		fade_progress = 0.0
		
	if is_fading:
		fade_progress += delta * 1.5
		var alpha_factor = max(0.0, 1.0 - fade_progress)
		scale = Vector3(alpha_factor, 1.0, alpha_factor)
		if fade_progress >= 1.0:
			beam_finished.emit()
			queue_free()
			return
			
	# Wander motion
	target_change_timer -= delta
	if target_change_timer <= 0.0 or global_position.distance_to(wander_target) < 3.0:
		_pick_new_wander_target()
		
	var move_dir = (wander_target - global_position)
	move_dir.y = 0.0
	if move_dir.length() > 0.1:
		global_position += move_dir.normalized() * move_speed * delta
		
	# Subtle visual pulse
	var pulse = 1.0 + sin(life_time * 6.0) * 0.08
	inner_mesh.scale = Vector3(pulse, 1.0, pulse)
	
	# Damage tick
	damage_timer -= delta
	if damage_timer <= 0.0:
		damage_timer = tick_interval
		_apply_burn_damage()

func _apply_burn_damage():
	if not area: return
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if not is_instance_valid(body): continue
		if body.is_in_group("Targetable") or body.is_in_group("NeutralCreature"):
			var hc = body.get_node_or_null("HealthComponent")
			if hc and not hc.is_dead:
				hc.take_damage(damage_per_tick)
