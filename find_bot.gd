extends SceneTree
func _init():
    var scenes = ["res://Scenes/Arena.tscn", "res://Scenes/Arena_4P.tscn"]
    for p in scenes:
        var scene = load(p)
        if scene:
            var inst = scene.instantiate()
            print("--- ", p, " ---")
            for node in inst.get_children():
                if node.get_script() and "BotAI.gd" in node.get_script().resource_path:
                    print("Found BotAI at root: ", node.name, " team: ", node.my_team)
                for child in node.get_children():
                    if child.get_script() and "BotAI.gd" in child.get_script().resource_path:
                        print("Found BotAI on child: ", child.name, " team: ", child.my_team)
    quit()
