extends SceneTree
func _init():
    var c = load("res://c.gd").new()
    root.add_child(c)
    c._ready()
    c._physics_process(0.1)
    quit()
