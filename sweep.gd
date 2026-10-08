extends SceneTree

func _init():
    var arena = load("res://Scenes/Arena.tscn")
    if arena:
        var inst = arena.instantiate()
        # Simulate setup_match
        if inst.has_method("setup_match"):
            inst.setup_match()
        print("Arena instantiated and setup successfully.")
        
    var arena_4p = load("res://Scenes/Arena_4P.tscn")
    if arena_4p:
        var inst_4p = arena_4p.instantiate()
        if inst_4p.has_method("setup_match"):
            inst_4p.setup_match()
        print("Arena_4P instantiated and setup successfully.")
            
    print("Sweep complete.")
    quit()
