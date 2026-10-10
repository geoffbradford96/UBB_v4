extends Node3D
class_name ArenaManager

@export var max_requisition: float = 100.0
var requisition_rate: float = 0.5

var active_biome: String = "SUNNY_PLAINS"
var solar_beam_timer: float = 15.0
var current_solar_beam: Node3D = null

var match_timer: float = 600.0
var sudden_death_active: bool = false
var beast_timer: float = 0.0
var beast_spawn_interval: float = 5.0
var beast_tentacle_scene = preload("res://Scenes/BeastTentacle.tscn")
var beast_mouth_scene = preload("res://Scenes/BeastMouth.tscn")
const StealthBrushScript = preload("res://Scripts/StealthBrush.gd")
const TerritorialCreatureScript = preload("res://Scripts/TerritorialCreature.gd")
const SolarBeamHazardScript = preload("res://Scripts/SolarBeamHazard.gd")
var placed_feature_records: Array = []


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
        var is_srv = multiplayer.is_server() if multiplayer.has_multiplayer_peer() else true
        pstate.team = "SideA" if is_srv else "SideB"
        pstate.ui = original_ui
        pstate.cam = original_cam
        if pstate.ui: pstate.ui.connect("ui_card_selected", Callable(self, "_on_ui_card_selected"))
        players.append(pstate)
        
    setup_match()
    
    if multiplayer.has_multiplayer_peer():
        if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
            multiplayer.peer_disconnected.connect(_on_peer_disconnected)
        if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
            multiplayer.server_disconnected.connect(_on_server_disconnected)

func _exit_tree():
    if multiplayer.has_multiplayer_peer():
        if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
            multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
        if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
            multiplayer.server_disconnected.disconnect(_on_server_disconnected)

func _on_peer_disconnected(id: int):
    print("Multiplayer peer disconnected: ", id)
    if GameState.current_mode.begins_with("ONLINE"):
        _end_match("OPPONENT DISCONNECTED! Victory by forfeit.")

func _on_server_disconnected():
    print("Multiplayer server disconnected.")
    if GameState.current_mode.begins_with("ONLINE"):
        _end_match("HOST DISCONNECTED FROM SERVER.")

func setup_match():

    var is_4p_mode = (GameState.current_mode == "LOCAL_SPLIT_4P" or GameState.map_selected == "Arena_4P.tscn")
    var is_6p_mode = (GameState.map_selected == "Arena_6P.tscn")
    var total_slots = 6 if is_6p_mode else (4 if is_4p_mode else 2)
    var local_players = players.size()
    var start_bot_idx = local_players
    
    if GameState.current_mode == "AI_VS_AI":
        start_bot_idx = 0
        if players.size() > 0 and players[0].ui:
            players[0].ui.visible = true # Keep spectator match UI visible!
    
    var teams_for_ai = []
    if is_6p_mode:
        total_slots = 6
        teams_for_ai = ["SideA", "SideA", "SideA", "SideB", "SideB", "SideB"]
    elif is_4p_mode:
        total_slots = max(GameState.match_player_count, 4)
        teams_for_ai = ["SideA", "SideA", "SideB", "SideB"]
    else:
        total_slots = 2
        teams_for_ai = ["SideA", "SideB"]
    
    if GameState.current_mode.begins_with("ONLINE"):
        return # Do not spawn AIs in online PvP matches!
        
    var profiles_for_slots = ["Player1", "Guest1", "Guest2", "Guest3", "Guest4", "Guest5"]
    for i in range(start_bot_idx, total_slots):
        var bot = BotAI.new()
        bot.my_team = teams_for_ai[i]
        bot.profile = profiles_for_slots[i] if i < profiles_for_slots.size() else "Guest1"
        
        # Pick enemy team
        bot.enemy_team = "SideB" if bot.my_team == "SideA" else "SideA"
        bot.difficulty = GameState.ai_difficulty
        
        # Base requisition rate matches player's base (0.5), balanced by difficulty
        if GameState.ai_difficulty == "EASY":
            bot.requisition_rate = 0.4
            bot.think_interval = 1.3
        elif GameState.ai_difficulty == "MEDIUM":
            bot.requisition_rate = 0.5
            bot.think_interval = 1.0
        elif GameState.ai_difficulty == "HARD":
            bot.requisition_rate = 0.6
            bot.think_interval = 0.7
        
        add_child(bot)
        print("Spawned BotAI for ", bot.my_team, " with profile ", bot.profile)

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
        
    var chosen_biome = GameState.map_biome if ("map_biome" in GameState and GameState.map_biome != "") else "SUNNY_PLAINS"
    if chosen_biome == "RANDOM":
        chosen_biome = "SUNNY_PLAINS" if randf() < 0.5 else "SCORCHING_DUNES"
    var map_seed = randi()
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if multiplayer.is_server():
            rpc("sync_map_environment", chosen_biome, map_seed)
    else:
        _apply_map_environment(chosen_biome, map_seed)
        
func _process(delta):
    if get_tree().paused: return

    if not sudden_death_active:
        match_timer -= delta
        if match_timer <= 0:
            match_timer = 0
            if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
                if multiplayer.is_server():
                    rpc("sync_start_sudden_death")
            else:
                sync_start_sudden_death()
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
            var h_pos = _get_clear_hazard_pos(map_size)
            var rx = h_pos.x
            var rz = h_pos.z
            var hazard_name = "BeastHazard_" + str(Time.get_ticks_usec())
            if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
                if multiplayer.is_server():
                    rpc("sync_spawn_hazard", rx, rz, randi() % 3 == 0, hazard_name)
            else:
                sync_spawn_hazard(rx, rz, randi() % 3 == 0, hazard_name)
                
    var b_root = get_node_or_null("BeastOfNothingness")
    if b_root and is_instance_valid(b_root):
        b_root.rotation.y += delta * 0.04
                
    _update_timer_ui()
    _animate_faction_structures(delta)
    _update_stealth_visibility()

    if active_biome == "SCORCHING_DUNES":
        if current_solar_beam == null or not is_instance_valid(current_solar_beam):
            current_solar_beam = null
            solar_beam_timer -= delta
            if solar_beam_timer <= 0.0:
                var is_host = not (multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and not multiplayer.is_server())
                if is_host:
                    var beam_dur = randf_range(20.0, 50.0)
                    var spawn_x = randf_range(-55.0, 55.0)
                    var spawn_z = randf_range(-55.0, 55.0)
                    var beam_id = "SolarBeam_" + str(Time.get_ticks_usec())
                    solar_beam_timer = randf_range(10.0, 30.0)
                    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
                        rpc("sync_spawn_solar_beam", spawn_x, spawn_z, beam_dur, beam_id)
                    else:
                        sync_spawn_solar_beam(spawn_x, spawn_z, beam_dur, beam_id)

    if GameState.current_mode == "AI_VS_AI" and players.size() > 0 and players[0].ui:
        var bot_a: BotAI = null
        var bot_b: BotAI = null
        for b in get_children():
            if b is BotAI:
                if b.my_team == "SideA" and bot_a == null: bot_a = b
                elif b.my_team != "SideA" and bot_b == null: bot_b = b
        if bot_a:
            players[0].ui.update_requisition(bot_a.current_requisition, bot_a.max_requisition)
        if bot_b:
            players[0].ui.update_enemy_requisition(bot_b.current_requisition, bot_b.max_requisition, bot_b.my_team)
    else:
        for p in players:
            var player_towers = 0
            for z in get_tree().get_nodes_in_group(p.team):
                if "Tower" in z.name: player_towers += 1
                
            var initial = initial_towers_per_team.get(p.team, 2)
            var dynamic_rate = requisition_rate + ((initial - player_towers) * (1.0 / max(1.0, float(initial))))
            if p.req < max_requisition:
                p.req += dynamic_rate * delta
                if p.req > max_requisition: p.req = max_requisition
                
            if p.ui:
                p.ui.update_requisition(p.req, max_requisition)
                if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
                    # Synchronize requisition across network for live enemy meter
                    rpc("sync_requisition", p.team, p.req)
                else:
                    # Find opposing bot to update enemy requisition display
                    var enemy_req = 0.0
                    var enemy_name = "Enemy AI"
                    for b in get_children():
                        if b is BotAI and b.my_team != p.team:
                            enemy_req = b.current_requisition
                            enemy_name = b.my_team + " AI"
                            break
                    p.ui.update_enemy_requisition(enemy_req, max_requisition, enemy_name)

@rpc("authority", "call_local", "reliable")
func sync_start_sudden_death():
    sudden_death_active = true
    match_timer = 0.0
    _start_beast_of_nothingness()

@rpc("any_peer", "unreliable")
func sync_requisition(team: String, req_val: float):
    if is_nan(req_val) or is_inf(req_val): return
    req_val = clampf(req_val, 0.0, max_requisition)
    for p in players:
        if p.ui and p.team != team:
            p.ui.update_enemy_requisition(req_val, max_requisition, "Opponent (" + team + ")")

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
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F8:
            print("DEBUG: Triggering Endgame Sudden Death collapse in 2 seconds!")
            match_timer = 2.0

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
                if p.cam and p.cam.get_viewport():
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
    # Security: Strict validation of card path
    if not card_path.begins_with("res://Data/Cards/") or not (card_path.ends_with(".tres") or card_path.ends_with(".tres.remap")):
        push_warning("Security: Rejected unauthorized card path in RPC: " + str(card_path))
        return
        
    # Security: Validate position coordinates (finite, non-NaN, within arena bounds)
    if is_nan(pos.x) or is_nan(pos.y) or is_nan(pos.z) or is_inf(pos.x) or is_inf(pos.y) or is_inf(pos.z):
        push_warning("Security: Rejected NaN/Inf position in sync_spawn_card")
        return
    if abs(pos.x) > 200.0 or abs(pos.z) > 200.0:
        push_warning("Security: Rejected out-of-bounds spawn position: " + str(pos))
        return
        
    # Security: Validate caller authority to prevent team spoofing
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        var sender_id = multiplayer.get_remote_sender_id()
        if sender_id != 0 and sender_id != 1: # Sent by client peer
            if team == "SideA":
                push_warning("Security: Client attempted to spawn unit for SideA (Host). Overriding to SideB.")
                team = "SideB"

    var data = load(card_path)
    if data == null or not "unit_scene" in data or data.unit_scene == null: return
    
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
        if "CommandBay" in unit.name:
            var faction = _get_team_faction(team)
            _build_structure_mesh(unit, faction, false)

func _on_koth_tick():
    if get_tree().paused: return
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if not multiplayer.is_server():
            return
            
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
        if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
            rpc("sync_koth_points", dominant_team, koth_points[dominant_team])
        if koth_points[dominant_team] >= 100:
            _end_match(dominant_team + " WINS THE MATCH BY KOTH!", dominant_team)

@rpc("authority", "unreliable")
func sync_koth_points(team: String, points: int):
    if koth_points.has(team):
        koth_points[team] = points


func _get_team_faction(team: String) -> String:
    for p in players:
        if p.team == team:
            var deck = []
            if GameState.player_decks.has(p.profile):
                deck = GameState.player_decks[p.profile]
            return _detect_faction_from_deck(deck)
            
    for child in get_children():
        if child.get_script() and "BotAI" in child.get_script().resource_path:
            if child.get("my_team") == team:
                var deck = child.get("deck")
                if deck != null and not deck.is_empty():
                    return _detect_faction_from_deck(deck)
                var p_name = child.get("profile")
                if p_name != null and GameState.player_decks.has(p_name):
                    return _detect_faction_from_deck(GameState.player_decks[p_name])
                    
    var opts = ["Dominion", "Void", "Rimworlders", "Pirates", "The Reach"]
    return opts[randi() % opts.size()]

func _detect_faction_from_deck(deck: Array) -> String:
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
        if "Base" in node.name or "Tower" in node.name or "CommandBay" in node.name:
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
    
    # ==========================================
    # 1. DOMINION OF SOL (MILITARY FORTRESS)
    # ==========================================
    if faction == "Dominion":
        var steel_mat = StandardMaterial3D.new(); steel_mat.albedo_color = Color(0.25, 0.28, 0.3); steel_mat.metallic = 0.85; steel_mat.roughness = 0.35
        var camo_mat = StandardMaterial3D.new(); camo_mat.albedo_color = Color(0.22, 0.32, 0.18); camo_mat.roughness = 0.7
        var amber_mat = StandardMaterial3D.new(); amber_mat.albedo_color = Color(1.0, 0.6, 0.1); amber_mat.emission_enabled = true; amber_mat.emission = Color(1.0, 0.5, 0.0); amber_mat.emission_energy_multiplier = 2.0
        
        if is_bay:
            # Military Supply Outpost & Communications Hub
            var bunker = MeshInstance3D.new(); bunker.mesh = BoxMesh.new(); bunker.mesh.size = Vector3(4.5, 2.2, 4.0)
            bunker.material_override = camo_mat; bunker.position.y = 1.1; mesh_node.add_child(bunker)
            var roof = MeshInstance3D.new(); roof.mesh = BoxMesh.new(); roof.mesh.size = Vector3(5.0, 0.4, 4.4)
            roof.material_override = steel_mat; roof.position.y = 2.4; mesh_node.add_child(roof)
            # Radar Dish
            var dish_pole = MeshInstance3D.new(); dish_pole.mesh = CylinderMesh.new(); dish_pole.mesh.top_radius = 0.08; dish_pole.mesh.bottom_radius = 0.08; dish_pole.mesh.height = 1.8
            dish_pole.material_override = steel_mat; dish_pole.position = Vector3(-1.5, 3.3, -1.2); mesh_node.add_child(dish_pole)
            var dish = MeshInstance3D.new(); dish.mesh = CylinderMesh.new(); dish.mesh.top_radius = 0.8; dish.mesh.bottom_radius = 0.1; dish.mesh.height = 0.3
            dish.material_override = steel_mat; dish.position = Vector3(-1.5, 4.2, -1.2); dish.rotation_degrees.x = 45; mesh_node.add_child(dish)
            mesh_node.set_meta("dominion_dish", dish)
            # Crates
            var c1 = MeshInstance3D.new(); c1.mesh = BoxMesh.new(); c1.mesh.size = Vector3(1.2, 1.0, 1.2)
            c1.material_override = steel_mat; c1.position = Vector3(1.6, 0.5, 1.8); mesh_node.add_child(c1)
        elif is_tower:
            # Heavy Military Pillbox with Twin Autocannons
            var base = MeshInstance3D.new(); base.mesh = CylinderMesh.new(); base.mesh.height = 3.2; base.mesh.bottom_radius = 2.2; base.mesh.top_radius = 1.8; base.mesh.radial_segments = 8
            base.material_override = camo_mat; base.position.y = 1.6; mesh_node.add_child(base)
            var ring = MeshInstance3D.new(); ring.mesh = TorusMesh.new(); ring.mesh.outer_radius = 2.0; ring.mesh.inner_radius = 1.7
            ring.material_override = steel_mat; ring.position.y = 3.2; mesh_node.add_child(ring)
            var turret = MeshInstance3D.new(); turret.mesh = BoxMesh.new(); turret.mesh.size = Vector3(2.2, 1.2, 2.4)
            turret.material_override = steel_mat; turret.position.y = 4.0; mesh_node.add_child(turret)
            mesh_node.set_meta("dominion_turret", turret)
            # Twin heavy barrels
            for i in range(2):
                var barrel = MeshInstance3D.new(); barrel.mesh = CylinderMesh.new(); barrel.mesh.height = 2.5; barrel.mesh.bottom_radius = 0.22; barrel.mesh.top_radius = 0.2
                barrel.material_override = steel_mat; barrel.rotation_degrees.x = 90; barrel.position = Vector3(-0.5 + i*1.0, 4.0, 1.6)
                mesh_node.add_child(barrel)
            # Sensor Visor
            var visor = MeshInstance3D.new(); visor.mesh = BoxMesh.new(); visor.mesh.size = Vector3(1.6, 0.25, 0.2)
            visor.material_override = amber_mat; visor.position = Vector3(0, 4.4, 1.25); mesh_node.add_child(visor)
        else:
            # Massive Command Citadel HQ
            var fort = MeshInstance3D.new(); fort.mesh = CylinderMesh.new(); fort.mesh.height = 4.5; fort.mesh.bottom_radius = 4.8; fort.mesh.top_radius = 4.2; fort.mesh.radial_segments = 8
            fort.material_override = camo_mat; fort.position.y = 2.25; mesh_node.add_child(fort)
            var upper = MeshInstance3D.new(); upper.mesh = BoxMesh.new(); upper.mesh.size = Vector3(5.0, 2.0, 5.0)
            upper.material_override = steel_mat; upper.position.y = 5.25; mesh_node.add_child(upper)
            var command_bridge = MeshInstance3D.new(); command_bridge.mesh = BoxMesh.new(); command_bridge.mesh.size = Vector3(4.0, 0.8, 4.0)
            command_bridge.material_override = amber_mat; command_bridge.position.y = 6.2; mesh_node.add_child(command_bridge)
            # Communications Antennae
            for i in range(4):
                var ant = MeshInstance3D.new(); ant.mesh = CylinderMesh.new(); ant.mesh.height = 4.0; ant.mesh.bottom_radius = 0.12; ant.mesh.top_radius = 0.04
                ant.material_override = steel_mat; ant.position = Vector3(cos(i*PI/2)*2.2, 7.5, sin(i*PI/2)*2.2); mesh_node.add_child(ant)
            # Searchlights
            for i in range(4):
                var light = MeshInstance3D.new(); light.mesh = SphereMesh.new(); light.mesh.radius = 0.35
                light.material_override = amber_mat; light.position = Vector3(cos(i*PI/2 + PI/4)*4.4, 4.6, sin(i*PI/2 + PI/4)*4.4); mesh_node.add_child(light)

    # ==========================================
    # 2. THE VOID SWARM (LIVING BIO-HORROR)
    # ==========================================
    elif faction == "Void":
        var flesh_mat = StandardMaterial3D.new(); flesh_mat.albedo_color = Color(0.18, 0.04, 0.28); flesh_mat.roughness = 0.4
        var chitin_mat = StandardMaterial3D.new(); chitin_mat.albedo_color = Color(0.06, 0.02, 0.1); chitin_mat.roughness = 0.2; chitin_mat.metallic = 0.4
        var eye_mat = StandardMaterial3D.new(); eye_mat.albedo_color = Color(1.0, 0.05, 0.85); eye_mat.emission_enabled = true; eye_mat.emission = Color(0.9, 0.0, 0.9); eye_mat.emission_energy_multiplier = 3.0
        
        if is_bay:
            # Spore Nest Cyst
            var cyst = MeshInstance3D.new(); cyst.mesh = SphereMesh.new(); cyst.mesh.radius = 2.2; cyst.mesh.height = 2.5
            cyst.material_override = flesh_mat; cyst.position.y = 1.25; mesh_node.add_child(cyst)
            for i in range(5):
                var pustule = MeshInstance3D.new(); pustule.mesh = SphereMesh.new(); pustule.mesh.radius = 0.6
                pustule.material_override = eye_mat
                var a = i * (2*PI/5)
                pustule.position = Vector3(cos(a)*1.6, 1.8, sin(a)*1.6); mesh_node.add_child(pustule)
        elif is_tower:
            # Flesh Spire with Giant Pulsing Eye
            var spire = MeshInstance3D.new(); spire.mesh = CylinderMesh.new(); spire.mesh.height = 6.0; spire.mesh.bottom_radius = 1.4; spire.mesh.top_radius = 0.4
            spire.material_override = flesh_mat; spire.position.y = 3.0; mesh_node.add_child(spire)
            # Talons surrounding the top
            for i in range(4):
                var talon = MeshInstance3D.new(); talon.mesh = CylinderMesh.new(); talon.mesh.height = 2.5; talon.mesh.bottom_radius = 0.25; talon.mesh.top_radius = 0.05
                talon.material_override = chitin_mat; talon.position = Vector3(cos(i*PI/2)*0.8, 5.5, sin(i*PI/2)*0.8)
                talon.rotation_degrees.x = 25 * cos(i*PI/2); talon.rotation_degrees.z = 25 * sin(i*PI/2); mesh_node.add_child(talon)
            var eye = MeshInstance3D.new(); eye.mesh = SphereMesh.new(); eye.mesh.radius = 1.3
            eye.material_override = eye_mat; eye.position.y = 5.8; mesh_node.add_child(eye)
            mesh_node.set_meta("void_eye", eye)
        else:
            # Massive Beating Swarm Hive Heart
            var hive = MeshInstance3D.new(); hive.mesh = SphereMesh.new(); hive.mesh.radius = 3.8; hive.mesh.height = 4.5
            hive.material_override = flesh_mat; hive.position.y = 2.5; mesh_node.add_child(hive)
            var heart = MeshInstance3D.new(); heart.mesh = SphereMesh.new(); heart.mesh.radius = 2.2
            heart.material_override = eye_mat; heart.position.y = 3.2; mesh_node.add_child(heart)
            mesh_node.set_meta("void_heart", heart)
            # Outer curved chitinous mandibles
            for i in range(8):
                var fang = MeshInstance3D.new(); fang.mesh = CylinderMesh.new(); fang.mesh.height = 5.0; fang.mesh.bottom_radius = 0.6; fang.mesh.top_radius = 0.05
                fang.material_override = chitin_mat
                var a = i * (2*PI/8)
                fang.position = Vector3(cos(a)*3.6, 2.5, sin(a)*3.6)
                fang.rotation_degrees.x = 35 * cos(a); fang.rotation_degrees.z = 35 * sin(a); mesh_node.add_child(fang)

    # ==========================================
    # 3. THE RIMWORLDERS (PRIMITIVE BEAST CITADEL)
    # ==========================================
    elif faction == "Rimworlders":
        var stone_mat = StandardMaterial3D.new(); stone_mat.albedo_color = Color(0.35, 0.32, 0.28); stone_mat.roughness = 0.95
        var wood_mat = StandardMaterial3D.new(); wood_mat.albedo_color = Color(0.42, 0.26, 0.14); wood_mat.roughness = 0.85
        var bone_mat = StandardMaterial3D.new(); bone_mat.albedo_color = Color(0.9, 0.88, 0.78); bone_mat.roughness = 0.5
        var fire_mat = StandardMaterial3D.new(); fire_mat.albedo_color = Color(1.0, 0.45, 0.0); fire_mat.emission_enabled = true; fire_mat.emission = Color(1.0, 0.35, 0.0); fire_mat.emission_energy_multiplier = 3.0
        
        if is_bay:
            # Beast Hide Yurt with Mammoth Horns
            var yurt = MeshInstance3D.new(); yurt.mesh = CylinderMesh.new(); yurt.mesh.bottom_radius = 2.8; yurt.mesh.top_radius = 0.2; yurt.mesh.height = 3.5
            yurt.material_override = wood_mat; yurt.position.y = 1.75; mesh_node.add_child(yurt)
            var horn1 = MeshInstance3D.new(); horn1.mesh = CylinderMesh.new(); horn1.mesh.top_radius = 0.05; horn1.mesh.bottom_radius = 0.3; horn1.mesh.height = 2.5
            horn1.material_override = bone_mat; horn1.position = Vector3(-1.4, 2.5, 1.4); horn1.rotation_degrees.z = -35; mesh_node.add_child(horn1)
            var horn2 = MeshInstance3D.new(); horn2.mesh = CylinderMesh.new(); horn2.mesh.top_radius = 0.05; horn2.mesh.bottom_radius = 0.3; horn2.mesh.height = 2.5
            horn2.material_override = bone_mat; horn2.position = Vector3(1.4, 2.5, 1.4); horn2.rotation_degrees.z = 35; mesh_node.add_child(horn2)
        elif is_tower:
            # Primitive Timber Watchtower with Spiked Skull Crest
            for i in range(4):
                var post = MeshInstance3D.new(); post.mesh = CylinderMesh.new(); post.mesh.height = 5.5; post.mesh.bottom_radius = 0.35; post.mesh.top_radius = 0.3
                post.material_override = wood_mat; post.position = Vector3(cos(i*PI/2 + PI/4)*1.3, 2.75, sin(i*PI/2 + PI/4)*1.3)
                mesh_node.add_child(post)
            var platform = MeshInstance3D.new(); platform.mesh = CylinderMesh.new(); platform.mesh.height = 0.6; platform.mesh.bottom_radius = 2.0; platform.mesh.top_radius = 2.0
            platform.material_override = wood_mat; platform.position.y = 5.3; mesh_node.add_child(platform)
            # Bone Spikes
            for i in range(6):
                var tusk = MeshInstance3D.new(); tusk.mesh = CylinderMesh.new(); tusk.mesh.height = 1.8; tusk.mesh.bottom_radius = 0.2; tusk.mesh.top_radius = 0.02
                tusk.material_override = bone_mat; var a = i * (2*PI/6)
                tusk.position = Vector3(cos(a)*1.8, 6.2, sin(a)*1.8); mesh_node.add_child(tusk)
        else:
            # Megalithic Beast Totem Fortress & Sacrificial Fire
            var stone_ring = MeshInstance3D.new(); stone_ring.mesh = CylinderMesh.new(); stone_ring.mesh.height = 2.0; stone_ring.mesh.bottom_radius = 4.8; stone_ring.mesh.top_radius = 4.4; stone_ring.mesh.radial_segments = 12
            stone_ring.material_override = stone_mat; stone_ring.position.y = 1.0; mesh_node.add_child(stone_ring)
            var fire = MeshInstance3D.new(); fire.mesh = SphereMesh.new(); fire.mesh.radius = 2.2
            fire.material_override = fire_mat; fire.position.y = 2.8; mesh_node.add_child(fire)
            mesh_node.set_meta("rimworld_fire", fire)
            # Gigantic Beast Tusks
            for i in range(4):
                var mammoth_tusk = MeshInstance3D.new(); mammoth_tusk.mesh = CylinderMesh.new(); mammoth_tusk.mesh.height = 6.0; mammoth_tusk.mesh.bottom_radius = 0.55; mammoth_tusk.mesh.top_radius = 0.05
                mammoth_tusk.material_override = bone_mat; var a = i * (PI/2) + PI/4
                mammoth_tusk.position = Vector3(cos(a)*3.6, 3.5, sin(a)*3.6)
                mammoth_tusk.rotation_degrees.x = -25 * cos(a); mammoth_tusk.rotation_degrees.z = -25 * sin(a)
                mesh_node.add_child(mammoth_tusk)

    # ==========================================
    # 4. PIRATE KINGDOMS (SCRAP CITADEL)
    # ==========================================
    elif faction == "Pirates":
        seed(node.name.hash())
        var rust_mat = StandardMaterial3D.new(); rust_mat.albedo_color = Color(0.55, 0.28, 0.12); rust_mat.metallic = 0.5; rust_mat.roughness = 0.9
        var dark_metal = StandardMaterial3D.new(); dark_metal.albedo_color = Color(0.2, 0.2, 0.2); dark_metal.metallic = 0.8
        var scrap_yellow = StandardMaterial3D.new(); scrap_yellow.albedo_color = Color(0.7, 0.55, 0.15); scrap_yellow.roughness = 0.8
        
        if is_bay:
            # Welded Cargo Container Bunker
            var crate = MeshInstance3D.new(); crate.mesh = BoxMesh.new(); crate.mesh.size = Vector3(3.5, 2.4, 3.5)
            crate.material_override = rust_mat; crate.position.y = 1.2; mesh_node.add_child(crate)
            var plate = MeshInstance3D.new(); plate.mesh = BoxMesh.new(); plate.mesh.size = Vector3(2.5, 1.2, 0.2)
            plate.material_override = scrap_yellow; plate.position = Vector3(0, 1.4, 1.85); mesh_node.add_child(plate)
            var exhaust = MeshInstance3D.new(); exhaust.mesh = CylinderMesh.new(); exhaust.mesh.height = 2.0; exhaust.mesh.top_radius = 0.2; exhaust.mesh.bottom_radius = 0.2
            exhaust.material_override = dark_metal; exhaust.position = Vector3(1.2, 2.8, -1.2); mesh_node.add_child(exhaust)
        elif is_tower:
            # Jury-Rigged Crane Turret with Scrap Shielding
            var derrick = MeshInstance3D.new(); derrick.mesh = BoxMesh.new(); derrick.mesh.size = Vector3(1.6, 5.5, 1.6)
            derrick.material_override = rust_mat; derrick.position.y = 2.75; mesh_node.add_child(derrick)
            var crane_boom = MeshInstance3D.new(); crane_boom.mesh = BoxMesh.new(); crane_boom.mesh.size = Vector3(4.2, 0.6, 0.8)
            crane_boom.material_override = scrap_yellow; crane_boom.position = Vector3(1.6, 5.6, 0); mesh_node.add_child(crane_boom)
            mesh_node.set_meta("pirate_crane", crane_boom)
            var cannon = MeshInstance3D.new(); cannon.mesh = CylinderMesh.new(); cannon.mesh.height = 3.0; cannon.mesh.top_radius = 0.3; cannon.mesh.bottom_radius = 0.35
            cannon.material_override = dark_metal; cannon.rotation_degrees.x = 90; cannon.position = Vector3(0, 4.5, 1.5); mesh_node.add_child(cannon)
        else:
            # Mad-Max Scrapyard Fortress with Chimneys & Spikes
            for i in range(5):
                var box = MeshInstance3D.new(); box.mesh = BoxMesh.new(); box.mesh.size = Vector3(2.8, 2.2, 4.2)
                box.material_override = rust_mat if i % 2 == 0 else scrap_yellow
                box.rotation_degrees.y = (i * 35.0)
                box.position = Vector3((i - 2.0) * 1.6, 1.1 + (i % 2) * 1.5, 0)
                mesh_node.add_child(box)
            # Giant smoking smokestacks
            for i in range(2):
                var stack = MeshInstance3D.new(); stack.mesh = CylinderMesh.new(); stack.mesh.height = 5.0; stack.mesh.bottom_radius = 0.55; stack.mesh.top_radius = 0.55
                stack.material_override = dark_metal; stack.position = Vector3(-1.8 + i*3.6, 4.5, -1.0); mesh_node.add_child(stack)
        randomize()

    # ==========================================
    # 5. THE REACH (PRISTINE CRYSTALLINE SPIRE)
    # ==========================================
    elif faction == "The Reach":
        var white_mat = StandardMaterial3D.new(); white_mat.albedo_color = Color(0.95, 0.97, 1.0); white_mat.roughness = 0.15; white_mat.metallic = 0.1
        var cyan_mat = StandardMaterial3D.new(); cyan_mat.albedo_color = Color(0.0, 0.88, 1.0); cyan_mat.emission_enabled = true; cyan_mat.emission = Color(0.0, 0.85, 1.0); cyan_mat.emission_energy_multiplier = 3.5
        
        if is_bay:
            # Porcelain Energy Pylon & Prisms
            var dome = MeshInstance3D.new(); dome.mesh = SphereMesh.new(); dome.mesh.radius = 2.0; dome.mesh.height = 2.2
            dome.material_override = white_mat; dome.position.y = 1.1; mesh_node.add_child(dome)
            var halo = MeshInstance3D.new(); halo.mesh = TorusMesh.new(); halo.mesh.outer_radius = 2.4; halo.mesh.inner_radius = 2.2
            halo.material_override = cyan_mat; halo.position.y = 1.2; mesh_node.add_child(halo)
        elif is_tower:
            # Floating Crystalline Obelisk (Anti-Gravity)
            var pad = MeshInstance3D.new(); pad.mesh = CylinderMesh.new(); pad.mesh.height = 0.5; pad.mesh.bottom_radius = 1.8; pad.mesh.top_radius = 1.8; pad.mesh.radial_segments = 6
            pad.material_override = white_mat; pad.position.y = 0.25; mesh_node.add_child(pad)
            var obelisk = MeshInstance3D.new(); obelisk.mesh = BoxMesh.new(); obelisk.mesh.size = Vector3(1.3, 4.5, 1.3)
            obelisk.material_override = white_mat; obelisk.position.y = 3.8; mesh_node.add_child(obelisk)
            var core = MeshInstance3D.new(); core.mesh = SphereMesh.new(); core.mesh.radius = 0.9
            core.material_override = cyan_mat; core.position.y = 1.6; mesh_node.add_child(core)
            mesh_node.set_meta("reach_hover", obelisk)
        else:
            # Towering Crystalline Nexus with Levitating Rings
            var base_dais = MeshInstance3D.new(); base_dais.mesh = CylinderMesh.new(); base_dais.mesh.height = 1.2; base_dais.mesh.bottom_radius = 4.6; base_dais.mesh.top_radius = 4.0; base_dais.mesh.radial_segments = 6
            base_dais.material_override = white_mat; base_dais.position.y = 0.6; mesh_node.add_child(base_dais)
            var spire = MeshInstance3D.new(); spire.mesh = CylinderMesh.new(); spire.mesh.height = 7.0; spire.mesh.bottom_radius = 1.4; spire.mesh.top_radius = 0.2
            spire.material_override = cyan_mat; spire.position.y = 4.2; mesh_node.add_child(spire)
            mesh_node.set_meta("reach_pillar", spire)
            for i in range(3):
                var ring = MeshInstance3D.new(); ring.mesh = TorusMesh.new(); ring.mesh.outer_radius = 2.6 - i*0.2; ring.mesh.inner_radius = 2.2 - i*0.2
                ring.material_override = white_mat; ring.position.y = 2.4 + i*1.6; mesh_node.add_child(ring)

func _update_timer_ui():
    for p in players:
        var ui = p.ui
        if not ui: continue
        var label = ui.get_node_or_null("TimerLabel")
        if not label: continue
        
        if not sudden_death_active:
            var m = int(floor(match_timer / 60.0))
            var s = int(match_timer) % 60
            var time_str = str(m) + ":" + ("0" if s < 10 else "") + str(s)
            if GameState.game_mode == "KOTH":
                time_str += " | Hill [A:" + str(koth_points["SideA"]) + " B:" + str(koth_points["SideB"]) + "]"
            label.text = time_str
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
        var angle = i * 8 * (PI / 180.0)
        var tooth = MeshInstance3D.new()
        tooth.mesh = CylinderMesh.new()
        tooth.mesh.top_radius = 0.0
        tooth.mesh.bottom_radius = 3.0
        tooth.mesh.height = 15.0
        tooth.material_override = teeth_mat
        tooth.position = Vector3(cos(angle) * 55, -45, sin(angle) * 55)
        tooth.rotation_degrees.x = -15
        tooth.rotation_degrees.y = -angle * (180.0/PI)
        beast_root.add_child(tooth)
        
    # Inner ring of razor fangs
    for i in range(30):
        var angle = (i * 12 + 6) * (PI / 180.0)
        var inner_tooth = MeshInstance3D.new()
        inner_tooth.mesh = CylinderMesh.new()
        inner_tooth.mesh.top_radius = 0.0
        inner_tooth.mesh.bottom_radius = 2.0
        inner_tooth.mesh.height = 10.0
        inner_tooth.material_override = teeth_mat
        inner_tooth.position = Vector3(cos(angle) * 48, -46, sin(angle) * 48)
        inner_tooth.rotation_degrees.x = -25
        inner_tooth.rotation_degrees.y = -angle * (180.0/PI)
        beast_root.add_child(inner_tooth)
        
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
        
    var scale_factor = 1.0
    if GameState.map_selected == "Arena_4P.tscn": scale_factor = 1.5
    elif GameState.map_selected == "Arena_6P.tscn": scale_factor = 2.2
    beast_root.scale = Vector3(scale_factor, 1.0, scale_factor)

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
    var tw = t.create_tween()
    tw.tween_property(t, "position:y", 0.0, 1.0)
    
    # Ground eruption shockwave burst
    var burst = MeshInstance3D.new()
    var tm = TorusMesh.new()
    tm.inner_radius = 1.0; tm.outer_radius = 2.4
    burst.mesh = tm
    var bmat = StandardMaterial3D.new()
    bmat.albedo_color = Color(0.35, 0.08, 0.45, 0.8)
    bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    bmat.emission_enabled = true
    bmat.emission = Color(0.4, 0.05, 0.5)
    bmat.emission_energy_multiplier = 2.0
    burst.material_override = bmat
    add_child(burst)
    burst.global_position = Vector3(rx, 0.05, rz)
    var btw = burst.create_tween()
    btw.tween_property(burst, "scale", Vector3(2.2, 1.0, 2.2), 0.6)
    btw.parallel().tween_property(bmat, "albedo_color:a", 0.0, 0.6)
    btw.tween_callback(burst.queue_free)

func _end_match(message: String, winning_team: String = ""):
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if multiplayer.is_server():
            rpc("sync_end_match", message, winning_team)
        else:
            if "DISCONNECTED" in message:
                sync_end_match(message, winning_team)
    else:
        sync_end_match(message, winning_team)

@rpc("authority", "call_local", "reliable")
func sync_end_match(message: String, winning_team: String = ""):
    if get_tree().paused: return
    get_tree().paused = true
    
    var my_team = "SideA"
    if players.size() == 1:
        my_team = players[0].team
        
    var final_message = message
    if winning_team != "" and players.size() == 1 and GameState.current_mode != "AI_VS_AI":
        if winning_team == my_team:
            final_message = "VICTORY! " + (message if not message.begins_with("DEFEAT") else "All opposing bases destroyed.")
        else:
            final_message = "DEFEAT! " + winning_team + " is victorious."
            
    print(final_message)
    var ui = get_node_or_null("InGameUI")
    if not ui and players.size() > 0: ui = players[0].ui
    
    if ui:
        var lbl = Label.new()
        lbl.text = final_message
        lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        lbl.add_theme_font_size_override("font_size", 48)
        lbl.add_theme_color_override("font_color", Color(1, 0.8, 0))
        lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
        lbl.add_theme_constant_override("outline_size", 8)
        ui.add_child(lbl)
        
    await get_tree().create_timer(4.0, true, false, true).timeout
    get_tree().paused = false
    GameState.disconnect_multiplayer()
    get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")

func _animate_faction_structures(delta):
    var t = Time.get_ticks_msec() * 0.001
    for s in get_tree().get_nodes_in_group("Targetable"):
        var f_mesh = s.get_meta("faction_mesh") if s.has_meta("faction_mesh") else null
        if f_mesh and is_instance_valid(f_mesh):
            if f_mesh.has_meta("reach_hover"):
                var node = f_mesh.get_meta("reach_hover")
                if is_instance_valid(node): node.position.y = 3.8 + sin(t * 2.5) * 0.35
            if f_mesh.has_meta("reach_pillar"):
                var node = f_mesh.get_meta("reach_pillar")
                if is_instance_valid(node): node.rotation.y += delta * 0.6
            if f_mesh.has_meta("void_heart"):
                var node = f_mesh.get_meta("void_heart")
                if is_instance_valid(node):
                    var beat = 1.0 + abs(sin(t * 3.5)) * 0.18
                    node.scale = Vector3(beat, beat, beat)
            if f_mesh.has_meta("void_eye"):
                var node = f_mesh.get_meta("void_eye")
                if is_instance_valid(node):
                    node.rotation.y = sin(t * 1.5) * 0.8
                    node.rotation.x = cos(t * 1.2) * 0.3
            if f_mesh.has_meta("dominion_dish"):
                var node = f_mesh.get_meta("dominion_dish")
                if is_instance_valid(node): node.rotation.y += delta * 1.5
            if f_mesh.has_meta("dominion_turret"):
                var node = f_mesh.get_meta("dominion_turret")
                if is_instance_valid(node): node.rotation.y = sin(t * 0.8) * 0.35
            if f_mesh.has_meta("rimworld_fire"):
                var node = f_mesh.get_meta("rimworld_fire")
                if is_instance_valid(node):
                    var fl = 1.0 + sin(t * 7.0) * 0.12
                    node.scale = Vector3(fl, 1.0 + cos(t * 9.0) * 0.15, fl)
            if f_mesh.has_meta("pirate_crane"):
                var node = f_mesh.get_meta("pirate_crane")
                if is_instance_valid(node): node.rotation.y = sin(t * 0.5) * 0.4

# =========================================================================
# MAP BIOME & PROCEDURAL ENVIRONMENT GENERATION
# =========================================================================

@rpc("authority", "call_local", "reliable")
func sync_map_environment(biome_name: String, seed_val: int):
    _apply_map_environment(biome_name, seed_val)

func _apply_map_environment(biome_name: String, seed_val: int):
    active_biome = biome_name
    seed(seed_val)
    print("Applying Map Biome: ", active_biome, " with seed: ", seed_val)
    
    _apply_biome_visuals(active_biome)
    
    var old_env = get_node_or_null("EnvironmentFeatures")
    if old_env: old_env.queue_free()
    
    var env_root = Node3D.new()
    env_root.name = "EnvironmentFeatures"
    add_child(env_root)
    
    if active_biome == "SUNNY_PLAINS":
        _generate_sunny_plains(env_root)
    elif active_biome == "SCORCHING_DUNES":
        _generate_scorching_dunes(env_root)

func _apply_biome_visuals(biome_name: String):
    var ground = get_node_or_null("Ground")
    var dir_light = get_node_or_null("DirectionalLight3D")
    var world_env = get_node_or_null("WorldEnvironment")
    
    if biome_name == "SUNNY_PLAINS":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.24, 0.54, 0.16)
                g_mat.roughness = 0.85
                g_mesh.material_override = g_mat
            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_color = Color(0.40, 0.28, 0.16)
                    p_mat.roughness = 0.9
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(1.0, 0.98, 0.90)
            dir_light.light_energy = 1.15
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.18, 0.35, 0.70)
                sky_mat.sky_horizon_color = Color(0.65, 0.75, 0.88)
                sky_mat.ground_bottom_color = Color(0.15, 0.15, 0.15)
                sky_mat.ground_horizon_color = Color(0.65, 0.75, 0.88)
                
    elif biome_name == "SCORCHING_DUNES":
        if ground:
            var g_mesh = ground.get_node_or_null("MeshInstance3D")
            if g_mesh:
                var g_mat = StandardMaterial3D.new()
                g_mat.albedo_color = Color(0.88, 0.72, 0.44) # Desert golden sand
                g_mat.roughness = 0.95
                g_mesh.material_override = g_mat
            for child in ground.get_children():
                if child is MeshInstance3D and child.name.begins_with("Path"):
                    var p_mat = StandardMaterial3D.new()
                    p_mat.albedo_color = Color(0.78, 0.62, 0.48) # Sandstone path
                    p_mat.roughness = 0.82
                    child.material_override = p_mat
        if dir_light:
            dir_light.light_color = Color(1.0, 0.94, 0.80)
            dir_light.light_energy = 1.45
            dir_light.shadow_enabled = true
        if world_env and world_env.environment and world_env.environment.sky:
            var sky_mat = world_env.environment.sky.sky_material
            if sky_mat is ProceduralSkyMaterial:
                sky_mat.sky_top_color = Color(0.25, 0.45, 0.75)
                sky_mat.sky_horizon_color = Color(0.95, 0.72, 0.45) # Amber heat haze
                sky_mat.ground_bottom_color = Color(0.35, 0.22, 0.10)
                sky_mat.ground_horizon_color = Color(0.85, 0.62, 0.38)
        solar_beam_timer = randf_range(10.0, 25.0)

func _get_clear_hazard_pos(map_size: float) -> Vector3:
    var attempts = 0
    while attempts < 35:
        attempts += 1
        var candidate = Vector3(randf_range(-map_size, map_size), 0.0, randf_range(-map_size, map_size))
        
        var obstructed = false
        for s in get_tree().get_nodes_in_group("Targetable"):
            if not is_instance_valid(s): continue
            if ("Base" in s.name or "Tower" in s.name or "CommandBay" in s.name) and candidate.distance_to(s.global_position) < 8.0:
                obstructed = true
                break
        if obstructed: continue
        
        for feat in placed_feature_records:
            if feat.get("type", "") == "dune" and candidate.distance_to(feat["pos"]) < feat["radius"] * 0.95:
                obstructed = true
                break
            elif (feat.get("type", "") == "pit" or feat.get("type", "") == "hill") and candidate.distance_to(feat["pos"]) < 7.5:
                obstructed = true
                break
            elif feat.get("type", "") == "tree" and candidate.distance_to(feat["pos"]) < 2.5:
                obstructed = true
                break
        if not obstructed:
            return candidate
            
    return Vector3(randf_range(-map_size * 0.6, map_size * 0.6), 0.0, randf_range(-map_size * 0.6, map_size * 0.6))

func _is_pos_clear(pos: Vector3, min_path_dist: float, min_struct_dist: float, self_radius: float = 3.0) -> bool:
    if abs(pos.x) > 78.0 or abs(pos.z) > 78.0: return false
    
    for node in get_tree().get_nodes_in_group("Targetable"):
        if not is_instance_valid(node): continue
        if "Base" in node.name or "Tower" in node.name or "CommandBay" in node.name:
            if pos.distance_to(node.global_position) < min_struct_dist + self_radius:
                return false
                
    if GameState.game_mode == "KOTH" or get_node_or_null("KotH_Zone") != null:
        if pos.distance_to(Vector3.ZERO) < 18.0 + self_radius:
            return false
            
    if GameState.map_selected == "Arena.tscn":
        if abs(pos.x) < (13.0 + min_path_dist + self_radius) and abs(pos.z) < 85.0:
            return false
    elif GameState.map_selected == "Arena_4P.tscn":
        if abs(pos.x) < (13.0 + min_path_dist + self_radius) or abs(pos.z) < (13.0 + min_path_dist + self_radius):
            return false
    elif GameState.map_selected == "Arena_6P.tscn":
        if pos.length() < (20.0 + self_radius): return false
        var angle = atan2(pos.z, pos.x)
        for rad_deg in [0, 60, 120, 180, 240, 300]:
            var target_rad = deg_to_rad(rad_deg)
            var diff = abs(angle_difference(angle, target_rad))
            var dist_to_lane = pos.length() * sin(diff)
            if diff < PI / 5.0 and dist_to_lane < (13.0 + min_path_dist + self_radius):
                return false

    for feat in placed_feature_records:
        var min_sep = feat.get("radius", 3.0) + self_radius
        if pos.distance_to(feat.get("pos", Vector3.ZERO)) < min_sep:
            return false
                
    return true

# --- Sunny Plains Generation ---
func _generate_sunny_plains(parent: Node3D):
    placed_feature_records.clear()
    
    var tree_count = randi_range(26, 34)
    var attempts = 0
    var placed_trees = 0
    while placed_trees < tree_count and attempts < 300:
        attempts += 1
        var candidate = Vector3(randf_range(-75.0, 75.0), 0.0, randf_range(-75.0, 75.0))
        if _is_pos_clear(candidate, 5.0, 14.0, 3.2):
            _create_procedural_tree(parent, candidate)
            placed_feature_records.append({"pos": candidate, "radius": 3.2, "type": "tree"})
            placed_trees += 1
            
    var brush_count = randi_range(8, 12)
    attempts = 0
    var placed_brush = 0
    while placed_brush < brush_count and attempts < 250:
        attempts += 1
        var side = -1.0 if randf() < 0.5 else 1.0
        var candidate = Vector3(side * randf_range(18.0, 55.0), 0.0, randf_range(-60.0, 60.0))
        if _is_pos_clear(candidate, 3.0, 12.0, 6.0):
            var brush = StealthBrushScript.new()
            brush.position = candidate
            brush.setup_visuals(randf_range(4.5, 6.2))
            parent.add_child(brush)
            placed_feature_records.append({"pos": candidate, "radius": 6.0, "type": "brush"})
            placed_brush += 1

func _create_procedural_tree(parent: Node3D, pos: Vector3):
    var tree_root = StaticBody3D.new()
    tree_root.position = pos
    tree_root.collision_layer = 1
    tree_root.collision_mask = 0
    
    var col = CollisionShape3D.new()
    var cyl = CylinderShape3D.new()
    cyl.radius = 0.5
    cyl.height = 3.5
    col.shape = cyl
    col.position.y = 1.75
    tree_root.add_child(col)
    
    var style = randi() % 3
    var scale_var = randf_range(0.85, 1.3)
    tree_root.scale = Vector3(scale_var, scale_var, scale_var)
    tree_root.rotation.y = randf() * TAU
    
    var bark_mat = StandardMaterial3D.new()
    bark_mat.albedo_color = Color(0.36, 0.22, 0.12) if style != 2 else Color(0.82, 0.82, 0.78)
    bark_mat.roughness = 0.85
    
    var trunk = MeshInstance3D.new()
    var trunk_mesh = CylinderMesh.new()
    trunk_mesh.top_radius = 0.28
    trunk_mesh.bottom_radius = 0.42
    trunk_mesh.height = 3.2
    trunk.mesh = trunk_mesh
    trunk.material_override = bark_mat
    trunk.position.y = 1.6
    tree_root.add_child(trunk)
    
    if style == 0:
        var leaf_mat = StandardMaterial3D.new()
        leaf_mat.albedo_color = Color(0.20, 0.56, 0.16)
        leaf_mat.roughness = 0.75
        for f_pos in [Vector3(0, 3.4, 0), Vector3(0.6, 3.8, 0.4), Vector3(-0.5, 3.6, -0.4)]:
            var leaves = MeshInstance3D.new()
            var sph = SphereMesh.new()
            sph.radius = 1.3
            sph.height = 2.4
            leaves.mesh = sph
            leaves.material_override = leaf_mat
            leaves.position = f_pos
            tree_root.add_child(leaves)
    elif style == 1:
        var pine_mat = StandardMaterial3D.new()
        pine_mat.albedo_color = Color(0.14, 0.42, 0.18)
        pine_mat.roughness = 0.8
        var tiers = [
            {"r": 1.6, "y": 2.6, "h": 1.4},
            {"r": 1.2, "y": 3.6, "h": 1.3},
            {"r": 0.8, "y": 4.5, "h": 1.2}
        ]
        for t in tiers:
            var cone = MeshInstance3D.new()
            var c_mesh = CylinderMesh.new()
            c_mesh.top_radius = 0.05
            c_mesh.bottom_radius = t["r"]
            c_mesh.height = t["h"]
            cone.mesh = c_mesh
            cone.material_override = pine_mat
            cone.position.y = t["y"]
            tree_root.add_child(cone)
    else:
        var birch_mat = StandardMaterial3D.new()
        birch_mat.albedo_color = Color(0.32, 0.66, 0.22)
        birch_mat.roughness = 0.75
        var crown = MeshInstance3D.new()
        var sph = SphereMesh.new()
        sph.radius = 1.5
        sph.height = 2.6
        crown.mesh = sph
        crown.material_override = birch_mat
        crown.position.y = 3.8
        tree_root.add_child(crown)
        
    parent.add_child(tree_root)

# --- Scorching Sand Dunes Generation ---
func _generate_scorching_dunes(parent: Node3D):
    placed_feature_records.clear()
    
    # 1. Higher Sand Dunes (14 to 18 obstacle dunes)
    var dune_count = randi_range(14, 18)
    var attempts = 0
    var placed_dunes = 0
    while placed_dunes < dune_count and attempts < 350:
        attempts += 1
        var candidate = Vector3(randf_range(-72.0, 72.0), 0.0, randf_range(-72.0, 72.0))
        if _is_pos_clear(candidate, 6.0, 16.0, 9.5):
            _create_sand_dune_blocker(parent, candidate)
            placed_feature_records.append({"pos": candidate, "radius": 9.5, "type": "dune"})
            placed_dunes += 1
            
    # 2. Scorpion Pits (2 territorial pits, each with 15 scorpions)
    for i in range(2):
        var side_x = -1.0 if i == 0 else 1.0
        attempts = 0
        while attempts < 100:
            attempts += 1
            var pit_candidate = Vector3(side_x * randf_range(28.0, 52.0), 0.0, randf_range(-45.0, 45.0))
            if _is_pos_clear(pit_candidate, 6.0, 16.0, 8.5):
                _create_scorpion_pit(parent, pit_candidate)
                placed_feature_records.append({"pos": pit_candidate, "radius": 8.5, "type": "pit"})
                break
        
    # 3. Ant Hills (2 territorial ant hills, each with 50 swarm ants)
    for i in range(2):
        var side_x = 1.0 if i == 0 else -1.0
        attempts = 0
        while attempts < 100:
            attempts += 1
            var hill_candidate = Vector3(side_x * randf_range(25.0, 48.0), 0.0, randf_range(-38.0, 38.0))
            if _is_pos_clear(hill_candidate, 6.0, 16.0, 8.0):
                _create_ant_hill(parent, hill_candidate)
                placed_feature_records.append({"pos": hill_candidate, "radius": 8.0, "type": "hill"})
                break

func _create_sand_dune_blocker(parent: Node3D, pos: Vector3):
    var dune = StaticBody3D.new()
    dune.position = pos
    dune.collision_layer = 1
    dune.collision_mask = 0
    
    var r_base = randf_range(6.5, 9.5)
    var h = randf_range(3.2, 4.2)
    
    var col = CollisionShape3D.new()
    var cyl = CylinderShape3D.new()
    cyl.radius = r_base * 0.85
    cyl.height = h
    col.shape = cyl
    col.position.y = h * 0.5
    dune.add_child(col)
    
    var dune_mesh = MeshInstance3D.new()
    var c_mesh = CylinderMesh.new()
    c_mesh.top_radius = r_base * 0.25
    c_mesh.bottom_radius = r_base
    c_mesh.height = h
    dune_mesh.mesh = c_mesh
    
    var dune_mat = StandardMaterial3D.new()
    dune_mat.albedo_color = Color(0.86, 0.70, 0.42)
    dune_mat.roughness = 0.95
    dune_mesh.material_override = dune_mat
    dune_mesh.position.y = h * 0.5
    dune_mesh.rotation.y = randf() * TAU
    dune.add_child(dune_mesh)
    
    dune.scale = Vector3(randf_range(1.1, 1.6), 1.0, randf_range(0.8, 1.2))
    parent.add_child(dune)

func _create_scorpion_pit(parent: Node3D, pos: Vector3):
    var pit_node = Node3D.new()
    pit_node.position = pos
    parent.add_child(pit_node)
    
    var pit_floor = MeshInstance3D.new()
    var pf_cyl = CylinderMesh.new()
    pf_cyl.top_radius = 6.8
    pf_cyl.bottom_radius = 7.2
    pf_cyl.height = 0.12
    var pf_mat = StandardMaterial3D.new()
    pf_mat.albedo_color = Color(0.64, 0.42, 0.26)
    pf_mat.roughness = 0.95
    pit_floor.mesh = pf_cyl
    pit_floor.material_override = pf_mat
    pit_floor.position.y = 0.06
    pit_node.add_child(pit_floor)
    
    var rock_mat = StandardMaterial3D.new()
    rock_mat.albedo_color = Color(0.72, 0.55, 0.40)
    rock_mat.roughness = 0.8
    for r in range(8):
        var ang = (TAU / 8.0) * r + randf_range(-0.15, 0.15)
        var rock = MeshInstance3D.new()
        var r_box = BoxMesh.new()
        var r_sz = randf_range(1.0, 1.8)
        r_box.size = Vector3(r_sz, randf_range(0.6, 1.2), r_sz)
        rock.mesh = r_box
        rock.material_override = rock_mat
        rock.position = Vector3(cos(ang) * 6.5, 0.4, sin(ang) * 6.5)
        rock.rotation = Vector3(randf() * 0.4, randf() * TAU, randf() * 0.4)
        pit_node.add_child(rock)
        
    for s in range(15):
        var ang = randf() * TAU
        var dist = randf_range(0.8, 4.8)
        var scorp = TerritorialCreatureScript.new()
        scorp.configure_creature("Scorpion", pos)
        scorp.position = pos + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist)
        parent.add_child(scorp)

func _create_ant_hill(parent: Node3D, pos: Vector3):
    var hill_node = Node3D.new()
    hill_node.position = pos
    parent.add_child(hill_node)
    
    var hill_mesh = MeshInstance3D.new()
    var hm = CylinderMesh.new()
    hm.top_radius = 0.6
    hm.bottom_radius = 3.8
    hm.height = 1.8
    var h_mat = StandardMaterial3D.new()
    h_mat.albedo_color = Color(0.74, 0.48, 0.24)
    h_mat.roughness = 0.95
    hill_mesh.mesh = hm
    hill_mesh.material_override = h_mat
    hill_mesh.position.y = 0.9
    hill_node.add_child(hill_mesh)
    
    var hole = MeshInstance3D.new()
    var hole_c = CylinderMesh.new()
    hole_c.top_radius = 0.35
    hole_c.bottom_radius = 0.35
    hole_c.height = 0.15
    var hole_mat = StandardMaterial3D.new()
    hole_mat.albedo_color = Color(0.12, 0.08, 0.05)
    hole.mesh = hole_c
    hole.material_override = hole_mat
    hole.position.y = 1.82
    hill_node.add_child(hole)
    
    for a in range(50):
        var ang = randf() * TAU
        var dist = randf_range(1.2, 5.5)
        var ant = TerritorialCreatureScript.new()
        ant.configure_creature("SwarmAnt", pos)
        ant.position = pos + Vector3(cos(ang) * dist, 0.1, sin(ang) * dist)
        parent.add_child(ant)

# --- Solar Light Beam Hazard Management ---
@rpc("authority", "call_local", "reliable")
func sync_spawn_solar_beam(x: float, z: float, dur: float, beam_name: String):
    var beam = SolarBeamHazardScript.new()
    beam.name = beam_name
    beam.position = Vector3(x, 0.0, z)
    beam.setup_duration(dur)
    beam.beam_finished.connect(_on_solar_beam_finished)
    add_child(beam)
    current_solar_beam = beam

func _on_solar_beam_finished():
    current_solar_beam = null
    solar_beam_timer = randf_range(10.0, 30.0)

# --- Stealth Brush Detection & Visibility ---
static func is_unit_stealthed_from(target: Node3D, observer: Node3D) -> bool:
    return GameState.is_unit_stealthed_from(target, observer)

func _update_stealth_visibility():
    var local_team = ""
    if players.size() > 0:
        local_team = players[0].team
    var is_spectator = (GameState.current_mode == "AI_VS_AI")
    
    for unit in get_tree().get_nodes_in_group("Targetable"):
        if not is_instance_valid(unit): continue
        if "Plane" in unit.name or unit.get("flight_height") != null or unit.get("is_flying") == true:
            unit.visible = true
            continue
            
        if unit.has_meta("in_stealth_grass") and unit.get_meta("in_stealth_grass", false):
            if is_spectator:
                unit.visible = true
                continue
            if local_team != "" and unit.is_in_group(local_team):
                unit.visible = true
            else:
                var revealed = false
                if local_team != "":
                    for ally in get_tree().get_nodes_in_group(local_team):
                        if is_instance_valid(ally) and ally != unit:
                            if ally.global_position.distance_to(unit.global_position) <= 4.0:
                                revealed = true
                                break
                unit.visible = revealed
        else:
            unit.visible = true

