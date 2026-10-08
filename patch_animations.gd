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
                    if not inst.has_node("AnimationPlayer"):
                        var ap = AnimationPlayer.new()
                        ap.name = "AnimationPlayer"
                        inst.add_child(ap)
                        ap.owner = inst
                        
                        var lib = AnimationLibrary.new()
                        var anim_idle = Animation.new(); anim_idle.length = 1.0; anim_idle.loop_mode = Animation.LOOP_LINEAR
                        var anim_walk = Animation.new(); anim_walk.length = 1.0; anim_walk.loop_mode = Animation.LOOP_LINEAR
                        var anim_attack = Animation.new(); anim_attack.length = 0.5
                        var anim_heal = Animation.new(); anim_heal.length = 0.5
                        var anim_repair = Animation.new(); anim_repair.length = 0.5
                        
                        lib.add_animation("idle", anim_idle)
                        lib.add_animation("walk", anim_walk)
                        lib.add_animation("attack", anim_attack)
                        lib.add_animation("heal", anim_heal)
                        lib.add_animation("repair", anim_repair)
                        ap.add_animation_library("", lib)
                        
                        var pack = PackedScene.new()
                        pack.pack(inst)
                        ResourceSaver.save(pack, path)
                        print("Patched animations for ", file_name)
            file_name = dir.get_next()
            
    print("Animation sweep complete.")
    quit()
