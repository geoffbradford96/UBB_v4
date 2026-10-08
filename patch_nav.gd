extends SceneTree

func _init():
    var dir = DirAccess.open("res://Scenes/Units/")
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if not dir.current_is_dir() and file_name.ends_with(".tscn"):
                var path = "res://Scenes/Units/" + file_name
                var scene = load(path)
                if scene:
                    var inst = scene.instantiate()
                    if not inst.has_node("NavigationAgent3D"):
                        var nav = NavigationAgent3D.new()
                        nav.name = "NavigationAgent3D"
                        # Set avoidance parameters if needed, but not strictly necessary if flocking handles it
                        inst.add_child(nav)
                        nav.owner = inst
                        
                        var pack = PackedScene.new()
                        pack.pack(inst)
                        ResourceSaver.save(pack, path)
                        print("Added NavigationAgent3D to ", file_name)
            file_name = dir.get_next()
            
    print("Nav injection complete.")
    quit()
