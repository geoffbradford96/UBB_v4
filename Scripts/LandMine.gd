extends Area3D

@export var damage: float = 100.0
var friendly_group: String = ""

func _ready():
	for g in get_groups():
		if g.begins_with("Side"): friendly_group = g
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.get("unit_attribute") == "Ethereal": return
	if body.has_method("get_groups") and not body.is_in_group(friendly_group):
		var hp = body.get_node_or_null("HealthComponent")
		if hp:
			hp.take_damage(damage)
			queue_free()
