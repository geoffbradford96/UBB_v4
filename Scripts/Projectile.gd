extends Area3D

var speed = 20.0
var damage = 20.0
var target: Node3D = null
var is_poisonous: bool = false

var lifetime: float = 6.0

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0.0 or target == null or not is_instance_valid(target):
		queue_free()
		return
	
	# Check proximity hit to avoid overshooting
	var dist = global_position.distance_to(target.global_position)
	if dist <= max(1.2, speed * delta):
		_hit_target(target)
		return
		
	# Move directly towards target
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta
	if direction != Vector3.ZERO:
		var up = Vector3.UP
		if abs(direction.dot(up)) > 0.98:
			up = Vector3.FORWARD
		look_at(global_position + direction, up)

func _hit_target(body):
	var health_node = body.get_node_or_null("HealthComponent")
	if health_node != null:
		health_node.take_damage(damage)
		if is_poisonous:
			health_node.apply_poison(4, damage * 0.5)
			
	# Impact visual spark
	var spark = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.5
	sm.height = 0.5
	spark.mesh = sm
	var mat = StandardMaterial3D.new()
	var spark_color = Color(1.0, 0.85, 0.3)
	var my_mesh = get_node_or_null("MeshInstance3D")
	if my_mesh and my_mesh.material_override and my_mesh.material_override is StandardMaterial3D:
		spark_color = my_mesh.material_override.albedo_color
	mat.albedo_color = spark_color
	mat.emission_enabled = true
	mat.emission = spark_color
	mat.emission_energy_multiplier = 3.0
	spark.material_override = mat
	get_tree().current_scene.add_child(spark)
	spark.global_position = global_position
	var tw = spark.create_tween()
	tw.tween_property(spark, "scale", Vector3(0.05, 0.05, 0.05), 0.15)
	tw.tween_callback(spark.queue_free)
	
	queue_free()

func _on_body_entered(body):
	if body == target:
		_hit_target(body)
