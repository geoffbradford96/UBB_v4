extends SceneTree

func _init():
    var gunner = load("res://Scenes/Units/RimworlderGunner.tscn")
    if gunner:
        var inst = gunner.instantiate()
        inst.set("attack_range", 18.0)
        var p = PackedScene.new()
        p.pack(inst)
        ResourceSaver.save(p, "res://Scenes/Units/RimworlderGunner.tscn")
        
    var mutant = load("res://Scenes/Units/RimworlderMutant.tscn")
    if mutant:
        var inst = mutant.instantiate()
        inst.set("attack_range", 5.0)
        var p = PackedScene.new()
        p.pack(inst)
        ResourceSaver.save(p, "res://Scenes/Units/RimworlderMutant.tscn")
        
    print("Ranges patched!")
    quit()
