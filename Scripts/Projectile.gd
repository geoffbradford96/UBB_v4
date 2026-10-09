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

func _hit_target(body):
	var health_node = body.get_node_or_null("HealthComponent")
	if health_node != null:
		health_node.take_damage(damage)
		if is_poisonous:
			health_node.apply_poison(4, damage * 0.5)
	queue_free()

func _on_body_entered(body):
	if body == target:
		_hit_target(body)
