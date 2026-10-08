extends SceneTree
func _init():
	var p = load("res://Scenes/Units/VoidSwarm/VoidCrawler.tscn")
	var s = p.instantiate()
	var m = s.get_node_or_null("MeshInstance3D")
	if m:
		for c in m.get_children():
			print(c.name)
	quit()
