extends SceneTree

func _init():
    var commanders = [
        {"name": "ScrapCommander", "faction": "Scrap", "hp": 500, "dmg": 60, "cost": 0, "color": Color(0.6, 0.3, 0.1)},
        {"name": "ReachCommander", "faction": "Reach", "hp": 1000, "dmg": 100, "cost": 0, "color": Color(0.15, 0.15, 0.2)}
    ]
    
    for c in commanders:
        var root = CharacterBody3D.new()
        root.name = c["name"]
        var script = load("res://Scripts/Hero.gd")
        root.set_script(script)
        root.set("max_health", c["hp"])
        root.set("damage", c["dmg"])
        root.set("attack_damage", c["dmg"])
        root.set("unit_attribute", "Organic")
        
        var col = CollisionShape3D.new()
        var cshape = BoxShape3D.new()
        cshape.size = Vector3(2, 3, 2)
        col.shape = cshape
        col.position.y = 1.5
        root.add_child(col)
        col.owner = root
        
        var mesh_node = MeshInstance3D.new()
        mesh_node.name = "MeshInstance3D"
        var bmesh = BoxMesh.new()
        bmesh.size = cshape.size
        mesh_node.mesh = bmesh
        mesh_node.position = col.position
        root.add_child(mesh_node)
        mesh_node.owner = root
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = c["color"]
        mat.metallic = 0.8
        mesh_node.material_override = mat
        
        # Add a big crown!
        var crown = MeshInstance3D.new()
        crown.mesh = CylinderMesh.new()
        crown.mesh.top_radius = 1.5; crown.mesh.bottom_radius = 0.8; crown.mesh.height = 1.0
        var cmat = StandardMaterial3D.new()
        cmat.albedo_color = Color(1, 0.8, 0) if c["faction"] == "Scrap" else Color(0.8, 0, 0)
        cmat.emission_enabled = true; cmat.emission = cmat.albedo_color
        crown.material_override = cmat
        crown.position.y = 2.0
        mesh_node.add_child(crown)
        crown.owner = root
        
        var hc = Node3D.new()
        hc.name = "HealthComponent"
        hc.set_script(load("res://Scripts/HealthComponent.gd"))
        root.add_child(hc)
        hc.owner = root
        
        var ap = AnimationPlayer.new()
        ap.name = "AnimationPlayer"
        root.add_child(ap)
        ap.owner = root
        
        var lib = AnimationLibrary.new()
        for aname in ["idle", "walk", "attack", "heal", "repair"]:
            var anim = Animation.new()
            anim.length = 1.0
            if aname in ["idle", "walk"]: anim.loop_mode = Animation.LOOP_LINEAR
            lib.add_animation(aname, anim)
        ap.add_animation_library("", lib)
        
        var pack = PackedScene.new()
        pack.pack(root)
        ResourceSaver.save(pack, "res://Scenes/Units/" + c["name"] + ".tscn")
        
        var card = ResourceLoader.load("res://Scripts/CardData.gd").new()
        card.card_name = c["name"]
        card.card_type = "Commander"
        card.cost = c["cost"]
        card.unit_scene = load("res://Scenes/Units/" + c["name"] + ".tscn")
        
        var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
        img.fill(mat.albedo_color)
        var itex = ImageTexture.create_from_image(img)
        card.card_art = itex
        ResourceSaver.save(card, "res://Data/Cards/" + c["name"] + ".tres")
        
    print("Commanders generated.")
    quit()
