extends Area3D

var speed = 20.0
var damage = 20.0
var target: Node3D = null
var is_poisonous: bool = false

func _physics_process(delta):
	if target == null or not is_instance_valid(target):
		queue_free() # Destroy projectile if target dies or disappears
		return
	
	# Move directly towards the target's position
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body == target:
		var health_node = body.get_node_or_null("HealthComponent")
		if health_node != null:
			health_node.take_damage(damage)
			if is_poisonous:
				health_node.apply_poison(4, damage * 0.5)
			
		queue_free()
