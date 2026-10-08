extends SceneTree

func _init():
	var paths = ["res://Scenes/Units/Sniper.tscn", "res://Scenes/Units/VoidSwarm/VoidCrawler.tscn"]
	for p in paths:
		var packed = load(p)
		if not packed: continue
		var scene = packed.instantiate()
		print("--- " + p + " ---")
		var m = scene.get_node_or_null("MeshInstance3D")
		if m:
			for c in m.get_children():
				if c is Node3D:
					print("  " + c.name + " -> Pos: " + str(c.position) + " | Rot: " + str(c.rotation_degrees) + " | Scale: " + str(c.scale))
					for cc in c.get_children():
						if cc is Node3D:
							print("    " + cc.name + " -> Pos: " + str(cc.position) + " | Rot: " + str(cc.rotation_degrees) + " | Scale: " + str(cc.scale))
							
		var ap = scene.get_node_or_null("AnimationPlayer")
		if ap:
			print("  Animations:")
			var lib = ap.get_animation_library("")
			if lib:
				for a_name in lib.get_animation_list():
					print("    - " + a_name)
					
	quit()
