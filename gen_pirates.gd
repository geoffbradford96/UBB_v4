extends SceneTree

func _init():
    var scrap_color = Color(0.6, 0.3, 0.1) # Rusty orange/brown
    var reach_color = Color(0.15, 0.15, 0.2) # Dark iron
    var neon_green = Color(0.1, 0.9, 0.2)
    var neon_pink = Color(0.9, 0.1, 0.7)
    var reach_red = Color(0.8, 0.1, 0.1)
    
    var unit_types = [
        {"name": "ScrapMelee", "base": "Unit.gd", "faction": "Scrap", "hp": 60, "dmg": 8, "cost": 10, "squad": 5},
        {"name": "ScrapRanged", "base": "Sniper.gd", "faction": "Scrap", "hp": 40, "dmg": 15, "cost": 12, "squad": 5},
        {"name": "ScrapTank", "base": "Tank.gd", "faction": "Scrap", "hp": 400, "dmg": 30, "cost": 40, "squad": 1},
        {"name": "ScrapPlane", "base": "Plane.gd", "faction": "Scrap", "hp": 150, "dmg": 20, "cost": 30, "squad": 1},
        {"name": "ScrapHunter", "base": "HeroHunter.gd", "faction": "Scrap", "hp": 90, "dmg": 25, "cost": 15, "squad": 1},
        {"name": "ScrapRepair", "base": "RepairMan.gd", "faction": "Scrap", "hp": 50, "dmg": 5, "cost": 15, "squad": 1},
        
        {"name": "ReachMelee", "base": "Unit.gd", "faction": "Reach", "hp": 120, "dmg": 18, "cost": 25, "squad": 5},
        {"name": "ReachRanged", "base": "Sniper.gd", "faction": "Reach", "hp": 80, "dmg": 30, "cost": 30, "squad": 5},
        {"name": "ReachTank", "base": "Tank.gd", "faction": "Reach", "hp": 800, "dmg": 60, "cost": 90, "squad": 1},
        {"name": "ReachPlane", "base": "Plane.gd", "faction": "Reach", "hp": 300, "dmg": 45, "cost": 70, "squad": 1},
        {"name": "ReachHunter", "base": "HeroHunter.gd", "faction": "Reach", "hp": 200, "dmg": 55, "cost": 40, "squad": 1},
        {"name": "ReachRepair", "base": "RepairMan.gd", "faction": "Reach", "hp": 100, "dmg": 10, "cost": 35, "squad": 1}
    ]
    
    for u in unit_types:
        var root = CharacterBody3D.new()
        root.name = u["name"]
        
        var script = load("res://Scripts/" + u["base"])
        root.set_script(script)
        
        root.set("max_health", u["hp"])
        root.set("damage", u["dmg"])
        if "attack_damage" in root: root.set("attack_damage", u["dmg"])
        root.set("unit_attribute", "Organic")
        
        # Collision
        var col = CollisionShape3D.new()
        var cshape = BoxShape3D.new()
        if "Tank" in u["name"]: cshape.size = Vector3(2, 2, 2)
        elif "Plane" in u["name"]: cshape.size = Vector3(2.5, 1, 2.5)
        else: cshape.size = Vector3(1, 2, 1)
        col.shape = cshape
        col.position.y = cshape.size.y / 2.0
        if "Plane" in u["name"]: col.position.y = 5.0
        root.add_child(col)
        col.owner = root
        
        # Mesh
        var mesh_node = MeshInstance3D.new()
        mesh_node.name = "MeshInstance3D"
        var bmesh = BoxMesh.new()
        bmesh.size = cshape.size
        mesh_node.mesh = bmesh
        mesh_node.position = col.position
        root.add_child(mesh_node)
        mesh_node.owner = root
        
        # Material
        var mat = StandardMaterial3D.new()
        if u["faction"] == "Scrap":
            mat.albedo_color = scrap_color
            mat.metallic = 0.5
            mat.roughness = 0.8
            # Add graffiti block
            var graf = MeshInstance3D.new()
            graf.mesh = BoxMesh.new()
            graf.mesh.size = Vector3(bmesh.size.x * 0.5, bmesh.size.y * 0.5, bmesh.size.z + 0.1)
            var gmat = StandardMaterial3D.new()
            gmat.albedo_color = neon_green if randf() > 0.5 else neon_pink
            gmat.emission_enabled = true
            gmat.emission = gmat.albedo_color
            graf.material_override = gmat
            mesh_node.add_child(graf)
            graf.owner = root
            
        else:
            mat.albedo_color = reach_color
            mat.metallic = 0.9
            mat.roughness = 0.4
            
        mesh_node.material_override = mat
        
        # Spikes!
        var spike_mat = StandardMaterial3D.new()
        if u["faction"] == "Scrap":
            spike_mat.albedo_color = Color(0.4, 0.4, 0.4)
            spike_mat.metallic = 0.8
        else:
            spike_mat.albedo_color = reach_red
            spike_mat.emission_enabled = true
            spike_mat.emission = reach_red
            
        for i in range(4 if "Tank" in u["name"] else 2):
            var spike = MeshInstance3D.new()
            spike.mesh = CylinderMesh.new()
            spike.mesh.top_radius = 0.0
            spike.mesh.bottom_radius = 0.2
            spike.mesh.height = 1.0
            spike.material_override = spike_mat
            spike.position.y = bmesh.size.y / 2.0
            spike.position.x = randf_range(-bmesh.size.x/2, bmesh.size.x/2)
            spike.position.z = randf_range(-bmesh.size.z/2, bmesh.size.z/2)
            spike.rotation_degrees.x = randf_range(-45, 45)
            spike.rotation_degrees.z = randf_range(-45, 45)
            mesh_node.add_child(spike)
            spike.owner = root
            
        # HealthComponent
        var hc = Node3D.new()
        hc.name = "HealthComponent"
        hc.set_script(load("res://Scripts/HealthComponent.gd"))
        root.add_child(hc)
        hc.owner = root
        
        # AnimationPlayer
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
        
        # Save Unit
        var pack = PackedScene.new()
        pack.pack(root)
        ResourceSaver.save(pack, "res://Scenes/Units/" + u["name"] + ".tscn")
        
        # Create Card UI resource
        var card = ResourceLoader.load("res://Scripts/CardData.gd").new()
        card.card_name = u["name"]
        card.cost = u["cost"]
        card.unit_scene = load("res://Scenes/Units/" + u["name"] + ".tscn")
        
        var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
        img.fill(mat.albedo_color)
        var itex = ImageTexture.create_from_image(img)
        card.card_art = itex
        card.spawn_count = u["squad"]
        ResourceSaver.save(card, "res://Data/Cards/" + u["name"] + ".tres")
        
    print("Pirates generated successfully.")
    quit()
