extends Node3D

@export var damage: float = 40.0
@export var radius: float = 12.0
@export var duration: float = 2.0

func _ready():
	# Visual flair for spells
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var tween = create_tween()
		mesh.scale = Vector3(0.1, 0.1, 0.1)
		tween.tween_property(mesh, "scale", Vector3(1, 1, 1), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		
	# Wait 0.5s for explosion animation to finish expanding
	await get_tree().create_timer(0.5).timeout
	
	var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
		
	var enemies = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if not node.is_in_group(my_team):
			enemies.append(node)
			
	for e in enemies:
		if is_instance_valid(e):
			var effective_radius = radius
			if "Base" in e.name: effective_radius += 5.0
			elif "Tower" in e.name or "CommandBay" in e.name: effective_radius += 2.0
			
			if global_position.distance_to(e.global_position) <= effective_radius:
				var hp = e.get_node_or_null("HealthComponent")
				if hp:
					hp.take_damage(damage)
					
	# Wait for particle effects to finish if any
	await get_tree().create_timer(duration).timeout
	queue_free()
