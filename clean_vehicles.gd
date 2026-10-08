extends SceneTree
func _init():
	var vehicles = ["Plane", "Tank"]
	for v in vehicles:
		var p = load("res://Scenes/Units/" + v + ".tscn")
		if not p: continue
		var scene = p.instantiate()
		var ap = scene.get_node_or_null("AnimationPlayer")
		if ap:
			ap.queue_free()
			var pack = PackedScene.new()
			pack.pack(scene)
			ResourceSaver.save(pack, "res://Scenes/Units/" + v + ".tscn")
			print("Cleaned ", v)
	quit()
