extends Node3D

@export var max_requisition: float = 100.0
var requisition_rate: float = 0.5

var initial_towers_per_team = {}
var koth_points = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0, "SideE": 0, "SideF": 0}

class LocalPlayerState:
    var p_id: int
    var profile: String
    var team: String
    var req: float = 0.0
    var active_commander: Node3D = null
    var selected_card_ui = null
    var ui: Control = null
    var cam: Camera3D = null
    var visuals: Array = []

var players: Array = []

func _ready():
    print("Initializing Arena in Mode: ", GameState.current_mode)
    
    var original_ui = get_node_or_null("InGameUI")
    var original_cam = get_node_or_null("ArenaCamera")
    
    if GameState.current_mode == "LOCAL_SPLIT_2P" or GameState.current_mode == "LOCAL_SPLIT_4P":
        var h_box = HBoxContainer.new()
        h_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        add_child(h_box)
        
        var is_4p = (GameState.current_mode == "LOCAL_SPLIT_4P" or GameState.map_selected == "Arena_4P.tscn")
        var is_6p = (GameState.map_selected == "Arena_6P.tscn")
        var p_count = 6 if is_6p else (4 if is_4p else 2)
        var teams = ["SideA", "SideB", "SideC", "SideD", "SideE", "SideF"]
        var profiles = ["Player1", "Guest1", "Guest2", "Guest3", "Guest4", "Guest5"]
        
        if original_ui: original_ui.get_parent().remove_child(original_ui)
        if original_cam: original_cam.get_parent().remove_child(original_cam)
        
        var left_vbox = VBoxContainer.new()
        left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        h_box.add_child(left_vbox)
        
        var right_vbox = VBoxContainer.new() if (is_4p or is_6p) else null
        if is_4p or is_6p:
            right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            h_box.add_child(right_vbox)
            
        for i in range(p_count):
            var pstate = LocalPlayerState.new()
            pstate.p_id = i + 1
            pstate.profile = profiles[i]
            pstate.team = "SideB" if (is_6p and i >= 3) else ("SideA" if is_6p else teams[i])
            
            var sub_c = SubViewportContainer.new()
            sub_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
            if not (is_4p or is_6p): sub_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            sub_c.stretch = true
            
            if is_4p or is_6p:
                if i % 2 == 0: left_vbox.add_child(sub_c)
                else: right_vbox.add_child(sub_c)
            else:
                h_box.add_child(sub_c)
                
            var vp = SubViewport.new()
            vp.use_3d_2d = true
            sub_c.add_child(vp)
            
            var cam = original_cam.duplicate()
            cam.player_id = pstate.p_id
            cam.assigned_team = pstate.team
            vp.add_child(cam)
            pstate.cam = cam
            
            var ui = original_ui.duplicate()
            ui.device_id = -1 if i == 0 else i - 1 # P1 is kb+joy0, P2 is joy0(if 1 controller) or joy1
            ui.player_profile = pstate.profile
            ui.player_id = pstate.p_id
            ui.connect("ui_card_selected", Callable(self, "_on_ui_card_selected"))
            vp.add_child(ui)
            pstate.ui = ui
            
            players.append(pstate)
            
        if original_ui: original_ui.queue_free()
        if original_cam: original_cam.queue_free()
        
    else:
        var pstate = LocalPlayerState.new()
        pstate.p_id = 1
        pstate.profile = "Player1"
        pstate.team = "SideA" if multiplayer.is_server() else "SideB"
        pstate.ui = original_ui
        pstate.cam = original_cam
        if pstate.ui: pstate.ui.connect("ui_card_selected", Callable(self, "_on_ui_card_selected"))
        players.append(pstate)
        
    setup_match()

func setup_match():

    var is_4p_mode = (GameState.current_mode == "LOCAL_SPLIT_4P" or GameState.map_selected == "Arena_4P.tscn")
    var is_6p_mode = (GameState.map_selected == "Arena_6P.tscn")
    var total_slots = 6 if is_6p_mode else (4 if is_4p_mode else 2)
    var local_players = players.size()
    var start_bot_idx = local_players
    
    if GameState.current_mode == "AI_VS_AI":
        start_bot_idx = 0
        if players.size() > 0 and players[0].ui:
            players[0].ui.visible = false
    
    var teams_for_ai = []
    if is_6p_mode:
        teams_for_ai = ["SideA", "SideA", "SideA", "SideB", "SideB", "SideB"]
    elif is_4p_mode:
        teams_for_ai = ["SideA", "SideB", "SideC", "SideD"]
    else:
        teams_for_ai = ["SideA", "SideB"]
    
    if GameState.current_mode.begins_with("ONLINE"):
        return # Do not spawn AIs in online PvP matches!
        
    for i in range(start_bot_idx, total_slots):
        var bot = BotAI.new()
        bot.my_team = teams_for_ai[i]
        
        # Pick enemy team
        bot.enemy_team = "SideB" if bot.my_team == "SideA" else "SideA"
        
        if GameState.ai_difficulty == "EASY": bot.requisition_rate = 0.3
        elif GameState.ai_difficulty == "MEDIUM": bot.requisition_rate = 0.5
        elif GameState.ai_difficulty == "HARD": bot.requisition_rate = 0.8
        
        add_child(bot)
        print("Spawned BotAI for ", bot.my_team)

    if GameState.game_mode == "KOTH":
        var timer = Timer.new()
        timer.wait_time = 1.0
        timer.autostart = true
        timer.connect("timeout", Callable(self, "_on_koth_tick"))
        add_child(timer)
    _apply_faction_visuals()
    
    for t in ["SideA", "SideB", "SideC", "SideD", "SideE", "SideF"]:
        var count = 0
        for z in get_tree().get_nodes_in_group(t):
            if "Tower" in z.name: count += 1
        initial_towers_per_team[t] = max(count, 2)
        
func _process(delta):
    if get_tree().paused: return
    for p in players:
        var player_towers = 0
        for z in get_tree().get_nodes_in_group(p.team):
            if "Tower" in z.name: player_towers += 1
            
        var initial = initial_towers_per_team.get(p.team, 2)
        var dynamic_rate = requisition_rate + ((initial - player_towers) * (1.0 / initial))
        if p.req < max_requisition:
            p.req += dynamic_rate * delta
            if p.req > max_requisition: p.req = max_requisition
            
        if p.ui:
            p.ui.update_requisition(p.req, max_requisition)

func _on_ui_card_selected(card_ui, ui_instance):
    var p = _get_player_by_ui(ui_instance)
    if not p: return
    
    if p.selected_card_ui:
        p.selected_card_ui.set_selected(false)
        
    if p.selected_card_ui == card_ui:
        p.selected_card_ui = null
        toggle_deployment_visuals(p, false)
        return
        
    p.selected_card_ui = card_ui
    p.selected_card_ui.set_selected(true)
    toggle_deployment_visuals(p, true, card_ui.card_data.is_spell)

func _get_player_by_ui(ui_instance) -> LocalPlayerState:
    for p in players:
        if p.ui == ui_instance: return p
    return null

func _get_player_by_device(device: int) -> LocalPlayerState:
    for p in players:
        if p.ui and p.ui.device_id == device: return p
    # Fallback to player 1
    if players.size() > 0: return players[0]
    return null

func _unhandled_input(event):
    var is_mouse_click = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
    
    var acted_player = null
    var screen_pos = Vector2.ZERO
    
    if is_mouse_click:
        acted_player = players[0] # Mouse always drives P1
        screen_pos = event.position
    elif event is InputEventJoypadButton and event.pressed:
        # We need to map standard UI accept or custom action to deployment
        for p in players:
            var prefix = "p" + str(p.p_id) + "_"
            if event.is_action_pressed(prefix + "action"):
                acted_player = p
                screen_pos = p.cam.get_viewport().get_visible_rect().size / 2.0
                break
                
    if acted_player and acted_player.selected_card_ui and acted_player.selected_card_ui.card_data:
        var camera = acted_player.cam
        if not camera: return
        var from = camera.project_ray_origin(screen_pos)
        var to = from + camera.project_ray_normal(screen_pos) * 1000.0
        
        var space_state = camera.get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(from, to)
        var result = space_state.intersect_ray(query)
        
        if result:
            var hit_pos = result.position
            if attempt_to_play_card(acted_player, acted_player.selected_card_ui.card_data, hit_pos):
                var played_ui = acted_player.selected_card_ui
                played_ui.set_selected(false)
                acted_player.selected_card_ui = null
                toggle_deployment_visuals(acted_player, false)
                
                if acted_player.ui:
                    acted_player.ui.discard.append(played_ui.card_data.card_name.replace(" ", "") + "Card")
                    acted_player.ui.draw_card(played_ui)

func toggle_deployment_visuals(p: LocalPlayerState, show: bool, is_spell: bool = false):
    for v in p.visuals:
        if is_instance_valid(v): v.queue_free()
    p.visuals.clear()
    
    if not show or is_spell: return
    
    for s in get_tree().get_nodes_in_group(p.team):
        if "Base" in s.name or "Tower" in s.name or "CommandBay" in s.name:
            var ring = MeshInstance3D.new()
            var torus = TorusMesh.new()
            torus.inner_radius = 24.5
            torus.outer_radius = 25.0
            ring.mesh = torus
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color(0.2, 0.8, 1.0, 0.5)
            mat.emission_enabled = true
            mat.emission = Color(0.2, 0.8, 1.0)
            mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
            ring.material_override = mat
            
            get_tree().current_scene.add_child(ring)
            ring.global_position = s.global_position + Vector3(0, 0.1, 0)
            p.visuals.append(ring)

func attempt_to_play_card(p: LocalPlayerState, data: Resource, target_position: Vector3) -> bool:
    if p.req < data.cost:
        print(p.team, " Not enough Requisition! Need ", data.cost, " but have ", snapped(p.req, 0.1))
        return false
        
    if data.card_type == "Commander":
        var has_commander = false
        for u in get_tree().get_nodes_in_group(p.team):
            if "Commander" in u.name or "Overlord" in u.name:
                has_commander = true
        if has_commander:
            print(p.team, " Cannot deploy! You already have an active Commander.")
            return false
                
    if not data.is_spell:
        var valid = false
        for z in get_tree().get_nodes_in_group(p.team):
            if "Base" in z.name or "Tower" in z.name or "CommandBay" in z.name:
                if target_position.distance_to(z.global_position) <= 25.0:
                    valid = true
                    break
        if not valid:
            print(p.team, " Cannot deploy! Must place units near a Tower or Command Bay.")
            return false
            
    p.req -= data.cost
    
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        var unique_id = str(randi())
        rpc("sync_spawn_card", data.resource_path, target_position, p.team, unique_id)
    else:
        sync_spawn_card(data.resource_path, target_position, p.team, str(randi()))
        
    return true

@rpc("any_peer", "call_local", "reliable")
func sync_spawn_card(card_path: String, pos: Vector3, team: String, unique_id: String):
    var data = load(card_path)
    if data == null: return
    
    var count = 1
    if "spawn_count" in data: count = data.spawn_count
    
    for i in range(count):
        var unit = data.unit_scene.instantiate()
        unit.name = data.card_name.replace(" ", "") + "_" + unique_id + "_" + str(i)
        
        if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
            var sync = MultiplayerSynchronizer.new()
            var config = SceneReplicationConfig.new()
            config.add_property(NodePath(":position"))
            config.add_property(NodePath(":rotation"))
            sync.replication_config = config
            unit.add_child(sync)
            
        
        add_child(unit)
        if data.is_spell: unit.global_position = pos
        else: unit.global_position = pos + Vector3(randf_range(-2.0, 2.0), 2.0, randf_range(-2.0, 2.0))
        unit.add_to_group(team)

func _on_koth_tick():
    if get_tree().paused: return
    var koth_zone = get_node_or_null("KotH_Zone")
    if not koth_zone: return
    var bodies = koth_zone.get_overlapping_bodies()
    var team_counts = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0, "SideE": 0, "SideF": 0}
    for b in bodies:
        if b.is_in_group("Targetable") and not "Base" in b.name and not "Tower" in b.name:
            if b.is_in_group("SideA"): team_counts["SideA"] += 1
            elif b.is_in_group("SideB"): team_counts["SideB"] += 1
            elif b.is_in_group("SideC"): team_counts["SideC"] += 1
            elif b.is_in_group("SideD"): team_counts["SideD"] += 1
            elif b.is_in_group("SideE"): team_counts["SideE"] += 1
            elif b.is_in_group("SideF"): team_counts["SideF"] += 1
    var dominant_team = ""
    var max_count = 0
    var tied = false
    for team in team_counts:
        if team_counts[team] > max_count:
            max_count = team_counts[team]
            dominant_team = team
            tied = false
        elif team_counts[team] == max_count and max_count > 0:
            tied = true
    if not tied and dominant_team != "":
        koth_points[dominant_team] += 1
        if koth_points[dominant_team] >= 100:
            print(dominant_team, " WINS THE MATCH BY KOTH!")
            get_tree().paused = true
            await get_tree().create_timer(3.0).timeout
            get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")


func _get_team_faction(team: String) -> String:
    for child in get_children():
        if child.get_script() and "BotAI" in child.get_script().resource_path:
            if child.my_team == team:
                if child.ai_profile == "Void Charcon": return "Void"
                if child.ai_profile == "The Great Beast Speaker": return "Rimworlders"
                if child.ai_profile == "Dominion Planet Commander": return "Dominion"
                if child.ai_profile == "The Scrap Pirate King": return "Pirates"
                if child.ai_profile == "The Reach Queen": return "The Reach"
                var options = ["Dominion", "Void", "Rimworlders", "Pirates", "The Reach"]
                return options[randi() % options.size()]
    for p in players:
        if p.team == team:
            var deck = []
            if GameState.player_decks.has(p.profile):
                deck = GameState.player_decks[p.profile]
            var v = 0; var r = 0; var d = 0; var pi = 0; var reach = 0
            for c in deck:
                if "Void" in c: v += 1
                elif "Rimworlder" in c or "Sky" in c or "Stone" in c or "Giant" in c or "Great" in c: r += 1
                elif "Scrap" in c: pi += 1
                elif "Reach" in c: reach += 1
                else: d += 1
            var mx = max(d, max(v, max(r, max(pi, reach))))
            if mx == v and v > 0: return "Void"
            if mx == r and r > 0: return "Rimworlders"
            if mx == pi and pi > 0: return "Pirates"
            if mx == reach and reach > 0: return "The Reach"
            return "Dominion"
    var opts = ["Dominion", "Void", "Rimworlders", "Pirates", "The Reach"]
    return opts[randi() % opts.size()]

func _apply_faction_visuals():
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if not multiplayer.is_server():
            return
            
    var teams = ["SideA", "SideB", "SideC", "SideD", "SideE", "SideF"]
    for team in teams:
        var faction = _get_team_faction(team)
        if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
            rpc("sync_faction", team, faction)
        else:
            apply_local_faction(team, faction)

@rpc("authority", "call_local", "reliable")
func sync_faction(team: String, faction: String):
    apply_local_faction(team, faction)

func apply_local_faction(team: String, faction: String):
    for node in get_tree().get_nodes_in_group(team):
        if "Base" in node.name or "Tower" in node.name:
            if "faction" in node: node.faction = faction
            _build_structure_mesh(node, faction, "Tower" in node.name)

func _build_structure_mesh(node, faction, is_tower):
    if node is CSGShape3D:
        var clear_mat = StandardMaterial3D.new()
        clear_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        clear_mat.albedo_color = Color(0, 0, 0, 0)
        node.material_override = clear_mat
        
    for c in node.get_children():
        if c is MeshInstance3D or (c is CSGShape3D and c != node):
            c.queue_free()
            
    var mesh_node = Node3D.new()
    node.add_child(mesh_node)
    
    if faction == "Dominion":
        if is_tower:
            var cyl = MeshInstance3D.new()
            cyl.mesh = CylinderMesh.new(); cyl.mesh.height = 4.0; cyl.mesh.bottom_radius = 1.0; cyl.mesh.top_radius = 1.0
            var mat_silver = StandardMaterial3D.new()
            mat_silver.albedo_color = Color(0.8, 0.8, 0.9); mat_silver.metallic = 0.8
            cyl.material_override = mat_silver; cyl.position.y = 2.0
            mesh_node.add_child(cyl)
            var dome = MeshInstance3D.new()
            dome.mesh = SphereMesh.new(); dome.mesh.radius = 1.2
            var mat_gold = StandardMaterial3D.new(); mat_gold.albedo_color = Color(1.0, 0.8, 0.0); mat_gold.metallic = 1.0
            dome.material_override = mat_gold; dome.position.y = 4.0
            mesh_node.add_child(dome)
        else:
            var box = MeshInstance3D.new()
            box.mesh = BoxMesh.new(); box.mesh.size = Vector3(5, 3, 5)
            var mat_gold = StandardMaterial3D.new()
            mat_gold.albedo_color = Color(0.9, 0.9, 0.9); mat_gold.metallic = 0.9
            box.material_override = mat_gold; box.position.y = 1.5
            mesh_node.add_child(box)
            var roof = MeshInstance3D.new()
            roof.mesh = PrismMesh.new(); roof.mesh.size = Vector3(5.5, 2, 5.5)
            var mat_blue = StandardMaterial3D.new(); mat_blue.albedo_color = Color(0.1, 0.3, 0.8); mat_blue.metallic = 0.5
            roof.material_override = mat_blue; roof.position.y = 4.0
            mesh_node.add_child(roof)
            
    elif faction == "Void":
        if is_tower:
            var eye_base = MeshInstance3D.new()
            eye_base.mesh = CylinderMesh.new(); eye_base.mesh.height = 3.0; eye_base.mesh.bottom_radius = 0.8; eye_base.mesh.top_radius = 0.8
            var mat_dark = StandardMaterial3D.new(); mat_dark.albedo_color = Color(0.1, 0.0, 0.2)
            eye_base.material_override = mat_dark; eye_base.position.y = 1.5
            mesh_node.add_child(eye_base)
            var eye = MeshInstance3D.new()
            eye.mesh = SphereMesh.new(); eye.mesh.radius = 1.5
            var mat_eye = StandardMaterial3D.new(); mat_eye.albedo_color = Color(0.9, 0.1, 0.9); mat_eye.emission_enabled = true; mat_eye.emission = Color(0.8, 0.0, 0.8)
            eye.material_override = mat_eye; eye.position.y = 3.5
            mesh_node.add_child(eye)
        else:
            var box = MeshInstance3D.new()
            box.mesh = SphereMesh.new(); box.mesh.radius = 3.5; box.mesh.height = 4.0
            var mat_dark = StandardMaterial3D.new(); mat_dark.albedo_color = Color(0.1, 0.1, 0.1)
            box.material_override = mat_dark; box.position.y = 2.0
            mesh_node.add_child(box)
            for i in range(4):
                var spike = MeshInstance3D.new()
                spike.mesh = CylinderMesh.new(); spike.mesh.top_radius = 0.0; spike.mesh.bottom_radius = 0.5; spike.mesh.height = 3.0
                var mat_scar = StandardMaterial3D.new(); mat_scar.albedo_color = Color(0.8, 0, 1.0); mat_scar.emission_enabled = true; mat_scar.emission = Color(0.8, 0, 1.0)
                spike.material_override = mat_scar; spike.position.y = 4.0
                var angle = i * (3.14159 * 2.0 / 4.0)
                spike.position.x = cos(angle) * 2.0; spike.position.z = sin(angle) * 2.0
                spike.rotation_degrees.x = sin(angle) * 30; spike.rotation_degrees.z = -cos(angle) * 30
                mesh_node.add_child(spike)
            
    elif faction == "Rimworlders":
        if is_tower:
            var mat_flesh = StandardMaterial3D.new(); mat_flesh.albedo_color = Color(0.2, 0.8, 0.3)
            for i in range(3):
                var stalk = MeshInstance3D.new()
                stalk.mesh = CapsuleMesh.new(); stalk.mesh.radius = 0.3; stalk.mesh.height = 3.0
                stalk.material_override = mat_flesh
                stalk.position.y = 1.5
                var angle = i * (3.14159 * 2.0 / 3.0)
                stalk.position.x = cos(angle) * 0.8; stalk.position.z = sin(angle) * 0.8
                stalk.rotation_degrees.x = sin(angle) * 15; stalk.rotation_degrees.z = -cos(angle) * 15
                mesh_node.add_child(stalk)
                var head = MeshInstance3D.new()
                head.mesh = SphereMesh.new(); head.mesh.radius = 0.6
                var mat_eye = StandardMaterial3D.new(); mat_eye.albedo_color = Color(1.0, 0.0, 0.0); mat_eye.emission_enabled = true; mat_eye.emission = Color(1.0, 0.0, 0.0)
                head.material_override = mat_eye; head.position.y = 1.5
                stalk.add_child(head)
        else:
            var mat_beast = StandardMaterial3D.new(); mat_beast.albedo_color = Color(0.1, 0.6, 0.2); mat_beast.emission_enabled = true; mat_beast.emission = Color(0.0, 0.3, 0.1)
            var core = MeshInstance3D.new()
            core.mesh = SphereMesh.new(); core.mesh.radius = 3.0; core.mesh.height = 4.0
            core.material_override = mat_beast; core.position.y = 2.0
            mesh_node.add_child(core)
            for i in range(5):
                var tent = MeshInstance3D.new()
                tent.mesh = CapsuleMesh.new(); tent.mesh.radius = 0.8; tent.mesh.height = 5.0
                tent.material_override = mat_beast
                var angle = i * (3.14159 * 2.0 / 5.0)
                tent.position.x = cos(angle) * 2.5; tent.position.z = sin(angle) * 2.5; tent.position.y = 2.0
                tent.rotation_degrees.x = sin(angle) * 45; tent.rotation_degrees.z = -cos(angle) * 45
                mesh_node.add_child(tent)
                
    elif faction == "Pirates":
        var mat_rust = StandardMaterial3D.new(); mat_rust.albedo_color = Color(0.6, 0.3, 0.1); mat_rust.metallic = 0.5; mat_rust.roughness = 0.9
        var mat_metal = StandardMaterial3D.new(); mat_metal.albedo_color = Color(0.4, 0.4, 0.4); mat_metal.metallic = 0.9; mat_metal.roughness = 0.6
        if is_tower:
            var base_cyl = MeshInstance3D.new()
            base_cyl.mesh = CylinderMesh.new(); base_cyl.mesh.height = 2.0; base_cyl.mesh.bottom_radius = 1.5; base_cyl.mesh.top_radius = 1.2
            base_cyl.material_override = mat_rust; base_cyl.position.y = 1.0
            mesh_node.add_child(base_cyl)
            var pole = MeshInstance3D.new()
            pole.mesh = CylinderMesh.new(); pole.mesh.height = 3.0; pole.mesh.bottom_radius = 0.3; pole.mesh.top_radius = 0.3
            pole.material_override = mat_metal; pole.position.y = 3.5
            mesh_node.add_child(pole)
            var turret = MeshInstance3D.new()
            turret.mesh = BoxMesh.new(); turret.mesh.size = Vector3(1.5, 1.0, 1.5)
            turret.material_override = mat_rust; turret.position.y = 5.0
            mesh_node.add_child(turret)
            var barrel = MeshInstance3D.new()
            barrel.mesh = CylinderMesh.new(); barrel.mesh.height = 2.0; barrel.mesh.bottom_radius = 0.2; barrel.mesh.top_radius = 0.2
            barrel.material_override = mat_metal; barrel.position.y = 5.0; barrel.position.z = 1.0; barrel.rotation_degrees.x = 90
            mesh_node.add_child(barrel)
        else:
            var hull = MeshInstance3D.new()
            hull.mesh = BoxMesh.new(); hull.mesh.size = Vector3(6, 2.5, 4)
            hull.material_override = mat_rust; hull.position.y = 1.25
            mesh_node.add_child(hull)
            var cabin = MeshInstance3D.new()
            cabin.mesh = BoxMesh.new(); cabin.mesh.size = Vector3(3, 2, 3)
            cabin.material_override = mat_metal; cabin.position.y = 3.5; cabin.position.x = -1.0
            mesh_node.add_child(cabin)
            var pipe = MeshInstance3D.new()
            pipe.mesh = CylinderMesh.new(); pipe.mesh.height = 3.0; pipe.mesh.bottom_radius = 0.4; pipe.mesh.top_radius = 0.4
            var mat_smoke = StandardMaterial3D.new(); mat_smoke.albedo_color = Color(0.2, 0.2, 0.2)
            pipe.material_override = mat_smoke; pipe.position.y = 5.0; pipe.position.x = 1.5
            mesh_node.add_child(pipe)
            
    elif faction == "The Reach":
        var mat_glass = StandardMaterial3D.new(); mat_glass.albedo_color = Color(0.1, 0.8, 1.0, 0.6); mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat_glass.emission_enabled = true; mat_glass.emission = Color(0.0, 0.5, 1.0)
        var mat_white = StandardMaterial3D.new(); mat_white.albedo_color = Color(0.9, 0.95, 1.0); mat_white.metallic = 0.2; mat_white.roughness = 0.1
        if is_tower:
            var obelisk = MeshInstance3D.new()
            obelisk.mesh = CylinderMesh.new(); obelisk.mesh.radial_segments = 4; obelisk.mesh.height = 4.5; obelisk.mesh.bottom_radius = 1.0; obelisk.mesh.top_radius = 0.2
            obelisk.material_override = mat_white; obelisk.position.y = 2.25
            obelisk.rotation_degrees.y = 45
            mesh_node.add_child(obelisk)
            var crystal = MeshInstance3D.new()
            crystal.mesh = PrismMesh.new(); crystal.mesh.size = Vector3(1.5, 2.0, 1.5)
            crystal.material_override = mat_glass; crystal.position.y = 5.5
            mesh_node.add_child(crystal)
            var crystal2 = MeshInstance3D.new()
            crystal2.mesh = PrismMesh.new(); crystal2.mesh.size = Vector3(1.5, 2.0, 1.5)
            crystal2.material_override = mat_glass; crystal2.position.y = 5.5; crystal2.rotation_degrees.x = 180
            mesh_node.add_child(crystal2)
        else:
            var plat = MeshInstance3D.new()
            plat.mesh = CylinderMesh.new(); plat.mesh.height = 1.0; plat.mesh.bottom_radius = 4.0; plat.mesh.top_radius = 3.5
            plat.material_override = mat_white; plat.position.y = 0.5
            mesh_node.add_child(plat)
            var core = MeshInstance3D.new()
            core.mesh = SphereMesh.new(); core.mesh.radius = 2.0; core.mesh.height = 4.0
            core.material_override = mat_glass; core.position.y = 2.5
            mesh_node.add_child(core)
            for i in range(3):
                var ring = MeshInstance3D.new()
                ring.mesh = TorusMesh.new(); ring.mesh.inner_radius = 2.5; ring.mesh.outer_radius = 3.0
                ring.material_override = mat_white; ring.position.y = 2.5
                ring.rotation_degrees.x = 90
                ring.rotation_degrees.y = i * 60
                mesh_node.add_child(ring)
