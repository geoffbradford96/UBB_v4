extends SceneTree
func _init():
	var spells = ["CallArtillery", "SupportingFire", "CommandBay"]
	for s in spells:
		var p = load("res://Scenes/Units/" + s + ".tscn")
		if not p: continue
		var scene = p.instantiate()
		var m = scene.get_node_or_null("MeshInstance3D")
		var has_limbs = false
		if m:
			for c in m.get_children():
				if "Leg" in c.name or "Arm" in c.name or "Cosmetic" in c.name:
					has_limbs = true
					c.queue_free()
		var ap = scene.get_node_or_null("AnimationPlayer")
		if ap:
			ap.queue_free()
			has_limbs = true
		if has_limbs:
			var pack = PackedScene.new()
			pack.pack(scene)
			ResourceSaver.save(pack, "res://Scenes/Units/" + s + ".tscn")
			print("Cleaned up ", s)
	quit()
