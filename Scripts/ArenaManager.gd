extends Node3D

@export var max_requisition: float = 100.0
var requisition_rate: float = 0.5

var match_timer: float = 600.0
var sudden_death_active: bool = false
var beast_timer: float = 0.0
var beast_spawn_interval: float = 5.0
var beast_tentacle_scene = preload("res://Scenes/BeastTentacle.tscn")
var beast_mouth_scene = preload("res://Scenes/BeastMouth.tscn")


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

    if "sudden_death_timer" in GameState:
        match_timer = float(GameState.sudden_death_timer)

    
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
            if is_6p: pstate.team = "SideB" if i >= 3 else "SideA"
            elif is_4p: pstate.team = "SideB" if i >= 2 else "SideA"
            else: pstate.team = "SideB" if i == 1 else "SideA"
            
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
    total_slots = GameState.match_player_count
    if is_6p_mode:
        teams_for_ai = ["SideA", "SideA", "SideA", "SideB", "SideB", "SideB"]
    elif is_4p_mode:
        teams_for_ai = ["SideA", "SideA", "SideB", "SideB"]
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

    if not sudden_death_active:
        match_timer -= delta
        if match_timer <= 0:
            match_timer = 0
            sudden_death_active = true
            _start_beast_of_nothingness()
    else:
        beast_timer -= delta
        if beast_timer <= 0:
            beast_timer = beast_spawn_interval
            beast_spawn_interval = max(0.5, beast_spawn_interval - 0.2)
            var hazard_count = get_tree().get_nodes_in_group("Beast").size()
            if hazard_count > 60: return # Cap beast entities to avoid lag
            var map_size = 40.0
            if GameState.map_selected == "Arena_4P.tscn": map_size = 70.0
            if GameState.map_selected == "Arena_6P.tscn": map_size = 110.0
            var rx = randf_range(-map_size, map_size)
            var rz = randf_range(-map_size, map_size)
            var hazard_name = "BeastHazard_" + str(Time.get_ticks_usec())
            if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
                if multiplayer.is_server():
                    rpc("sync_spawn_hazard", rx, rz, randi() % 3 == 0, hazard_name)
            else:
                sync_spawn_hazard(rx, rz, randi() % 3 == 0, hazard_name)
                
    _update_timer_ui()

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
        if acted_player.cam and acted_player.cam.get_viewport() != get_viewport():
            # Adjust mouse coordinates if cam is in a subviewport
            var vp = acted_player.cam.get_viewport()
            var win_size = get_viewport().get_visible_rect().size
            var vp_size = vp.get_visible_rect().size
            screen_pos.x = (screen_pos.x / win_size.x) * vp_size.x
            screen_pos.y = (screen_pos.y / win_size.y) * vp_size.y

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

func toggle_deployment_visuals(p: LocalPlayerState, should_show: bool, is_spell: bool = false):
    for v in p.visuals:
        if is_instance_valid(v): v.queue_free()
    p.visuals.clear()
    
    if not should_show or is_spell: return
    
    for s in get_tree().get_nodes_in_group(p.team):
        if "Base" in s.name or "Tower" in s.name or "CommandBay" in s.name:
            var ring = MeshInstance3D.new()
            var torus = TorusMesh.new()
            torus.outer_radius = 25.0
            torus.inner_radius = 24.5
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
            if u.is_in_group("CommanderUnit") or "Commander" in u.name or "Overlord" in u.name or "GreatBeastSpeaker" in u.name:
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
        
        var hc = unit.get_node_or_null("HealthComponent")
        if hc and "max_hp" in data:
            if hc.has_method("set_max_health"):
                hc.set_max_health(data.max_hp)
                
        if "card_type" in data and data.card_type == "Commander":
            unit.add_to_group("CommanderUnit")

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
            _end_match(dominant_team + " WINS THE MATCH BY KOTH!")


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
    node.set_meta("faction_mesh", mesh_node)
    
    var is_bay = "CommandBay" in node.name
    if faction == "Dominion":
        if is_bay:
            var box = MeshInstance3D.new(); box.mesh = BoxMesh.new(); box.mesh.size = Vector3(4, 2, 4)
            var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.2, 0.4, 0.8); mat.metallic = 0.8
            box.material_override = mat; box.position.y = 1.0; mesh_node.add_child(box)
        elif is_tower:
            var base = MeshInstance3D.new(); base.mesh = CylinderMesh.new(); base.mesh.height = 3.0; base.mesh.bottom_radius = 2.0; base.mesh.top_radius = 1.5
            var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.6, 0.65, 0.7); mat.metallic = 0.8
            base.material_override = mat; base.position.y = 1.5; mesh_node.add_child(base)
            var dome = MeshInstance3D.new(); dome.mesh = SphereMesh.new(); dome.mesh.radius = 1.4
            var d_mat = StandardMaterial3D.new(); d_mat.albedo_color = Color(0.2, 0.4, 0.8); d_mat.metallic = 0.9
            dome.material_override = d_mat; dome.position.y = 3.2; mesh_node.add_child(dome)
            for i in range(2):
                var barrel = MeshInstance3D.new(); barrel.mesh = CylinderMesh.new(); barrel.mesh.height = 2.0; barrel.mesh.bottom_radius = 0.2; barrel.mesh.top_radius = 0.2
                barrel.material_override = mat; barrel.rotation_degrees.x = 90; barrel.position = Vector3(-0.4 + i*0.8, 3.2, 1.0)
                mesh_node.add_child(barrel)
        else:
            var body = MeshInstance3D.new(); body.mesh = CylinderMesh.new(); body.mesh.height = 4.0; body.mesh.bottom_radius = 4.0; body.mesh.top_radius = 3.5; body.mesh.radial_segments = 8
            var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.7, 0.7, 0.75); mat.metallic = 0.9
            body.material_override = mat; body.position.y = 2.0; mesh_node.add_child(body)
            var core = MeshInstance3D.new(); core.mesh = SphereMesh.new(); core.mesh.radius = 2.0
            var c_mat = StandardMaterial3D.new(); c_mat.albedo_color = Color(0.1, 0.5, 1.0); c_mat.emission_enabled = true; c_mat.emission = Color(0.1, 0.5, 1.0)
            core.material_override = c_mat; core.position.y = 4.5; mesh_node.add_child(core)
            for i in range(4):
                var ant = MeshInstance3D.new(); ant.mesh = CylinderMesh.new(); ant.mesh.height = 3.0; ant.mesh.bottom_radius = 0.1; ant.mesh.top_radius = 0.05
                ant.material_override = mat; ant.position = Vector3(cos(i*PI/2)*3.0, 4.5, sin(i*PI/2)*3.0); mesh_node.add_child(ant)
                
    elif faction == "Void":
        if is_bay:
            var blob = MeshInstance3D.new(); blob.mesh = SphereMesh.new(); blob.mesh.radius = 2.0
            var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.2, 0.0, 0.3)
            blob.material_override = mat; blob.position.y = 1.0; mesh_node.add_child(blob)
        elif is_tower:
            var spire = MeshInstance3D.new(); spire.mesh = CylinderMesh.new(); spire.mesh.height = 5.0; spire.mesh.bottom_radius = 1.0; spire.mesh.top_radius = 0.2
            var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.15, 0.05, 0.25)
            spire.material_override = mat; spire.position.y = 2.5; mesh_node.add_child(spire)
            var eye = MeshInstance3D.new(); eye.mesh = SphereMesh.new(); eye.mesh.radius = 1.2
            var e_mat = StandardMaterial3D.new(); e_mat.albedo_color = Color(0.9, 0.1, 0.9); e_mat.emission_enabled = true; e_mat.emission = Color(0.8, 0.1, 0.8)
            eye.material_override = e_mat; eye.position.y = 5.5; mesh_node.add_child(eye)
            mesh_node.set_meta("void_eye", eye)
        else:
            var heart = MeshInstance3D.new(); heart.mesh = SphereMesh.new(); heart.mesh.radius = 3.5
            var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.4, 0.05, 0.4); mat.emission_enabled = true; mat.emission = Color(0.2, 0.0, 0.3)
            heart.material_override = mat; heart.position.y = 2.5; mesh_node.add_child(heart)
            for i in range(6):
                var spike = MeshInstance3D.new(); spike.mesh = CylinderMesh.new(); spike.mesh.height = 4.0; spike.mesh.bottom_radius = 0.5; spike.mesh.top_radius = 0.0
                var s_mat = StandardMaterial3D.new(); s_mat.albedo_color = Color(0.1, 0.1, 0.1)
                spike.material_override = s_mat; spike.position = Vector3(cos(i*PI/3)*3.5, 2.0, sin(i*PI/3)*3.5)
                spike.rotation_degrees.x = 45 * cos(i*PI/3); spike.rotation_degrees.z = 45 * sin(i*PI/3)
                mesh_node.add_child(spike)
            mesh_node.set_meta("void_heart", heart)
            
    elif faction == "Rimworlders":
        if is_bay:
            var tent = MeshInstance3D.new(); tent.mesh = CylinderMesh.new(); tent.mesh.bottom_radius = 2.5; tent.mesh.top_radius = 0; tent.mesh.height = 3.0
            var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.5, 0.3, 0.1)
            tent.material_override = mat; tent.position.y = 1.5; mesh_node.add_child(tent)
        elif is_tower:
            var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.4, 0.25, 0.1)
            for i in range(4):
                var leg = MeshInstance3D.new(); leg.mesh = CylinderMesh.new(); leg.mesh.height = 5.0; leg.mesh.bottom_radius = 0.3; leg.mesh.top_radius = 0.3
                leg.material_override = mat; leg.position = Vector3(cos(i*PI/2 + PI/4)*1.2, 2.5, sin(i*PI/2 + PI/4)*1.2)
                leg.rotation_degrees.x = 10 * cos(i*PI/2 + PI/4); leg.rotation_degrees.z = 10 * sin(i*PI/2 + PI/4)
                mesh_node.add_child(leg)
            var plat = MeshInstance3D.new(); plat.mesh = CylinderMesh.new(); plat.mesh.height = 0.5; plat.mesh.bottom_radius = 1.8; plat.mesh.top_radius = 1.8
            plat.material_override = mat; plat.position.y = 5.0; mesh_node.add_child(plat)
            var spikes = MeshInstance3D.new(); spikes.mesh = SphereMesh.new(); spikes.mesh.radius = 1.0
            var s_mat = StandardMaterial3D.new(); s_mat.albedo_color = Color(0.2, 0.2, 0.2)
            spikes.material_override = s_mat; spikes.position.y = 6.0; mesh_node.add_child(spikes)
        else:
            var pit = MeshInstance3D.new(); pit.mesh = CylinderMesh.new(); pit.mesh.height = 1.0; pit.mesh.bottom_radius = 4.0; pit.mesh.top_radius = 4.5
            var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.3, 0.2, 0.1)
            pit.material_override = mat; pit.position.y = 0.5; mesh_node.add_child(pit)
            var fire = MeshInstance3D.new(); fire.mesh = SphereMesh.new(); fire.mesh.radius = 2.0
            var f_mat = StandardMaterial3D.new(); f_mat.albedo_color = Color(1.0, 0.4, 0.0); f_mat.emission_enabled = true; f_mat.emission = Color(1.0, 0.3, 0.0); f_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; f_mat.albedo_color.a = 0.8
            fire.material_override = f_mat; fire.position.y = 1.5; mesh_node.add_child(fire)
            for i in range(8):
                var wall = MeshInstance3D.new(); wall.mesh = CylinderMesh.new(); wall.mesh.height = 3.5; wall.mesh.bottom_radius = 0.4; wall.mesh.top_radius = 0.1
                wall.material_override = mat; wall.position = Vector3(cos(i*PI/4)*3.8, 1.75, sin(i*PI/4)*3.8)
                mesh_node.add_child(wall)
                
    elif faction == "Pirates":
        var r_mat = StandardMaterial3D.new(); r_mat.albedo_color = Color(0.5, 0.25, 0.1); r_mat.metallic = 0.4
        if is_bay:
            var crate = MeshInstance3D.new(); crate.mesh = BoxMesh.new(); crate.mesh.size = Vector3(3, 2.5, 3)
            crate.material_override = r_mat; crate.position.y = 1.25; mesh_node.add_child(crate)
        elif is_tower:
            var crane = MeshInstance3D.new(); crane.mesh = BoxMesh.new(); crane.mesh.size = Vector3(1, 6, 1)
            crane.material_override = r_mat; crane.position.y = 3.0; mesh_node.add_child(crane)
            var arm = MeshInstance3D.new(); arm.mesh = BoxMesh.new(); arm.mesh.size = Vector3(4, 0.5, 0.5)
            arm.material_override = r_mat; arm.position = Vector3(1.5, 5.5, 0); mesh_node.add_child(arm)
            var line = MeshInstance3D.new(); line.mesh = CylinderMesh.new(); line.mesh.height = 3.0; line.mesh.bottom_radius = 0.05; line.mesh.top_radius = 0.05
            var l_mat = StandardMaterial3D.new(); l_mat.albedo_color = Color(0.1, 0.1, 0.1)
            line.material_override = l_mat; line.position = Vector3(3.0, 4.0, 0); mesh_node.add_child(line)
            var magnet = MeshInstance3D.new(); magnet.mesh = CylinderMesh.new(); magnet.mesh.height = 0.5; magnet.mesh.bottom_radius = 1.0; magnet.mesh.top_radius = 1.0
            magnet.material_override = r_mat; magnet.position = Vector3(3.0, 2.5, 0); mesh_node.add_child(magnet)
        else:
            for i in range(5):
                var box = MeshInstance3D.new(); box.mesh = BoxMesh.new(); box.mesh.size = Vector3(2.5, 2.5, 4.5)
                var mat = StandardMaterial3D.new(); mat.albedo_color = Color(randf_range(0.3, 0.7), randf_range(0.2, 0.4), 0.1); mat.metallic = 0.6
                box.material_override = mat; box.position = Vector3(randf_range(-2, 2), 1.25 + (i/2.0), randf_range(-2, 2))
                box.rotation_degrees.y = randf_range(0, 360)
                mesh_node.add_child(box)
            var stack = MeshInstance3D.new(); stack.mesh = CylinderMesh.new(); stack.mesh.height = 4.0; stack.mesh.bottom_radius = 0.6; stack.mesh.top_radius = 0.6
            stack.material_override = r_mat; stack.position = Vector3(0, 4.0, 0); mesh_node.add_child(stack)
            
    elif faction == "The Reach":
        var w_mat = StandardMaterial3D.new(); w_mat.albedo_color = Color(0.9, 0.95, 1.0); w_mat.roughness = 0.1
        var c_mat = StandardMaterial3D.new(); c_mat.albedo_color = Color(0.0, 0.8, 1.0); c_mat.emission_enabled = true; c_mat.emission = Color(0.0, 0.8, 1.0)
        if is_bay:
            var dome = MeshInstance3D.new(); dome.mesh = SphereMesh.new(); dome.mesh.radius = 2.0; dome.mesh.height = 2.0
            dome.material_override = w_mat; dome.position.y = 1.0; mesh_node.add_child(dome)
        elif is_tower:
            var pad = MeshInstance3D.new(); pad.mesh = CylinderMesh.new(); pad.mesh.height = 0.5; pad.mesh.bottom_radius = 1.5; pad.mesh.top_radius = 1.5
            pad.material_override = w_mat; pad.position.y = 0.25; mesh_node.add_child(pad)
            var obelisk = MeshInstance3D.new(); obelisk.mesh = BoxMesh.new(); obelisk.mesh.size = Vector3(1.2, 4.0, 1.2)
            obelisk.material_override = w_mat; obelisk.position.y = 3.5; mesh_node.add_child(obelisk)
            var core = MeshInstance3D.new(); core.mesh = SphereMesh.new(); core.mesh.radius = 0.8
            core.material_override = c_mat; core.position.y = 1.5; mesh_node.add_child(core)
            mesh_node.set_meta("reach_hover", obelisk)
        else:
            var base = MeshInstance3D.new(); base.mesh = CylinderMesh.new(); base.mesh.height = 1.0; base.mesh.bottom_radius = 4.0; base.mesh.top_radius = 3.5; base.mesh.radial_segments = 6
            base.material_override = w_mat; base.position.y = 0.5; mesh_node.add_child(base)
            var pillar = MeshInstance3D.new(); pillar.mesh = CylinderMesh.new(); pillar.mesh.height = 6.0; pillar.mesh.bottom_radius = 1.5; pillar.mesh.top_radius = 1.5
            pillar.material_override = c_mat; pillar.position.y = 3.5; mesh_node.add_child(pillar)
            for i in range(3):
                var ring = MeshInstance3D.new(); ring.mesh = TorusMesh.new(); ring.mesh.outer_radius = 2.5; ring.mesh.inner_radius = 2.0
                ring.material_override = w_mat; ring.position.y = 2.0 + i*1.5; mesh_node.add_child(ring)
            mesh_node.set_meta("reach_pillar", pillar)


func _update_timer_ui():
    for p in players:
        var ui = p.ui
        if not ui: continue
        var label = ui.get_node_or_null("TimerLabel")
        if not label: continue
        
        if not sudden_death_active:
            var m = int(floor(match_timer / 60.0))
            var s = int(match_timer) % 60
            label.text = str(m) + ":" + ("0" if s < 10 else "") + str(s)
            label.modulate = Color(1, 1, 1)
            label.scale = Vector2(1.0, 1.0)
        else:
            label.text = "SUDDEN DEATH!"
            label.modulate = Color(1, 0, 0)
            label.scale = Vector2(1.2 + sin(Time.get_ticks_msec()*0.01)*0.1, 1.2 + sin(Time.get_ticks_msec()*0.01)*0.1)

func _start_beast_of_nothingness():
    print("THE BEAST OF NOTHINGNESS AWAKENS!")
    var beast_root = Node3D.new()
    beast_root.name = "BeastOfNothingness"
    add_child(beast_root)
    
    var torus = MeshInstance3D.new()
    torus.mesh = TorusMesh.new()
    torus.mesh.outer_radius = 80.0
    torus.mesh.inner_radius = 50.0
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.2, 0.1, 0.3)
    mat.emission_enabled = true
    mat.emission = Color(0.5, 0.0, 0.8)
    mat.emission_energy_multiplier = 0.5
    torus.material_override = mat
    torus.position = Vector3(0, -50, 0)
    beast_root.add_child(torus)
    
    var teeth_mat = StandardMaterial3D.new()
    teeth_mat.albedo_color = Color(0.7, 0.7, 0.7)
    for i in range(45):
        var angle = i * 8 * (3.14159/180.0)
        var tooth = MeshInstance3D.new()
        tooth.mesh = CylinderMesh.new()
        tooth.mesh.top_radius = 0.0
        tooth.mesh.bottom_radius = 3.0
        tooth.mesh.height = 15.0
        tooth.material_override = teeth_mat
        tooth.position = Vector3(cos(angle) * 55, -45, sin(angle) * 55)
        tooth.rotation_degrees.x = -15
        tooth.rotation_degrees.y = -angle * (180.0/3.14159)
        beast_root.add_child(tooth)
        
    for i in range(40):
        var eye = MeshInstance3D.new()
        eye.mesh = SphereMesh.new()
        eye.mesh.radius = 2.5
        var eye_mat = StandardMaterial3D.new()
        eye_mat.albedo_color = Color(1.0, 0.0, 0.0)
        eye_mat.emission_enabled = true
        eye_mat.emission = Color(1.0, 0.0, 0.0)
        eye.material_override = eye_mat
        var angle = (i * 9 + 4) * (3.14159/180.0)
        eye.position = Vector3(cos(angle) * 62, -48, sin(angle) * 62)
        beast_root.add_child(eye)
        
    var tw = create_tween()
    tw.tween_property(beast_root, "position:y", 20.0, 30.0) # slowly rise (to y=20 so mouth frames the arena)

@rpc("authority", "call_local", "reliable")
func sync_spawn_hazard(rx: float, rz: float, is_mouth: bool, unique_name: String):
    var scn = beast_mouth_scene if is_mouth else beast_tentacle_scene
    if not scn: return
    var t = scn.instantiate()
    t.name = unique_name
    add_child(t)
    t.global_position = Vector3(rx, -5, rz)
    var tw = create_tween()
    tw.tween_property(t, "position:y", 0.0, 1.0)

func _end_match(message: String):
    if get_tree().paused: return
    get_tree().paused = true
    print(message)
    var ui = get_node_or_null("InGameUI")
    if not ui and players.size() > 0: ui = players[0].ui
    
    if ui:
        var lbl = Label.new()
        lbl.text = message
        lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        lbl.add_theme_font_size_override("font_size", 48)
        lbl.add_theme_color_override("font_color", Color(1, 0.8, 0))
        lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
        lbl.add_theme_constant_override("outline_size", 8)
        ui.add_child(lbl)
        
    await get_tree().create_timer(4.0).timeout
    get_tree().paused = false
    get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")
