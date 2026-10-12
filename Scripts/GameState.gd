extends Node

var current_mode = "LOCAL"
var player_faction = "Dominion of Sol"
var local_player_team: String = "SideA"
var player_vision_enabled: bool = true
var previous_menu: String = "res://Scenes/MainMenu.tscn"

# Supports up to 6 local players
var player_decks = {
	"Player1": [],
	"Guest1": [],
	"Guest2": [],
	"Guest3": [],
	"Guest4": [],
	"Guest5": []
}
var editing_profile = "Player1"

var peer = ENetMultiplayerPeer.new()

# Match Setup Options
var ai_difficulty = "MEDIUM"
var game_mode = "DESTROY_BASE"
var map_selected = "Arena.tscn"
var map_biome = "SUNNY_PLAINS"
var match_player_count = 2
var sudden_death_timer = 600.0

# Corpse & Battlefield Debris Settings
var corpse_max_count: int = 30 # Options: 10, 30, 60, 120
var corpse_duration: float = 15.0 # Options: 5.0, 15.0, 30.0, 60.0, -1.0 (Permanent)
var active_corpses: Array = []

func _ready():
	print("Global GameState is active!")
	load_decks()
	load_settings()

func load_settings():
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		corpse_max_count = cfg.get_value("gameplay", "corpse_max_count", 30)
		corpse_duration = cfg.get_value("gameplay", "corpse_duration", 15.0)

func register_corpse(corpse_node: Node3D):
	if not is_instance_valid(corpse_node): return
	active_corpses.append(corpse_node)
	while active_corpses.size() > max(1, corpse_max_count):
		var oldest = active_corpses.pop_front()
		if is_instance_valid(oldest):
			_fade_and_free_corpse(oldest)
	if corpse_duration > 0.0:
		var tw = corpse_node.create_tween()
		tw.tween_interval(corpse_duration)
		tw.tween_callback(Callable(self, "_on_corpse_expired").bind(corpse_node))

func _on_corpse_expired(corpse_node: Node3D):
	active_corpses.erase(corpse_node)
	if is_instance_valid(corpse_node):
		_fade_and_free_corpse(corpse_node)

func _fade_and_free_corpse(node: Node3D):
	if not is_instance_valid(node): return
	var tw = node.create_tween()
	tw.tween_property(node, "scale", node.scale * 0.001, 1.2)
	tw.tween_callback(node.queue_free)
	
func save_decks():
	var save_path = "user://local_decks.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json = JSON.stringify(player_decks)
		file.store_string(json)
		file.close()
		
func load_decks():
	var load_path = "user://local_decks.json"
	if FileAccess.file_exists(load_path):
		var file = FileAccess.open(load_path, FileAccess.READ)
		var json = file.get_as_text()
		file.close()
		
		var parsed = JSON.parse_string(json)
		if typeof(parsed) == TYPE_DICTIONARY:
			for key in parsed.keys():
				player_decks[key] = parsed[key]
				
	if not player_decks.has("Player1") or player_decks["Player1"].is_empty():
		player_decks["Player1"] = ["CommanderCard", "CheapGruntCard", "SupportingFireCard", "MedicCard", "CallArtilleryCard", "SniperCard"]
	if not player_decks.has("Guest1") or player_decks["Guest1"].is_empty():
		player_decks["Guest1"] = ["VoidOverlordCard", "VoidCrawlerCard", "VoidSpitterCard", "VoidStalkerCard", "VoidMeteorCard", "VoidSpikerCard"]
	if not player_decks.has("Guest2") or player_decks["Guest2"].is_empty():
		player_decks["Guest2"] = ["GreatBeastSpeakerCard", "RimworlderGunnerCard", "RimworlderMeleeCard", "SkyBeetleCard", "StoneOctopusCard", "RimworlderLeviathanCard"]
	if not player_decks.has("Guest3") or player_decks["Guest3"].is_empty():
		player_decks["Guest3"] = ["ScrapCommanderCard", "ScrapMeleeCard", "ScrapRangedCard", "ScrapTankCard", "ScrapPlaneCard", "ScrapMechCard"]
	if not player_decks.has("Guest4") or player_decks["Guest4"].is_empty():
		player_decks["Guest4"] = ["ReachCommanderCard", "ReachMeleeCard", "ReachRangedCard", "ReachTankCard", "ReachPlaneCard", "ReachMechCard"]
	if not player_decks.has("Guest5") or player_decks["Guest5"].is_empty():
		player_decks["Guest5"] = ["CommanderCard", "HeavyTankCard", "DominionMechCard", "FighterPlaneCard", "HeroHunterCard", "RepairManCard"]

# Backwards compatibility for older scripts that used player_deck
var player_deck:
	get:
		return player_decks["Player1"]
	set(value):
		player_decks["Player1"] = value

func host_game() -> Error:
	disconnect_multiplayer()
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(8910, match_player_count) 
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Hosting game on port 8910")
	else:
		print("Failed to host game on port 8910: Error ", error)
	return error

func join_game(ip: String) -> Error:
	disconnect_multiplayer()
	peer = ENetMultiplayerPeer.new()
	var clean_ip = ip.strip_edges()
	if clean_ip.is_empty():
		clean_ip = "127.0.0.1"
	var error = peer.create_client(clean_ip, 8910)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Connecting to game at ", clean_ip, ":8910")
	else:
		print("Failed to join game at ", clean_ip, ": Error ", error)
	return error

func disconnect_multiplayer():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer = null
	if peer:
		peer.close()
	peer = ENetMultiplayerPeer.new()

func is_unit_stealthed_from(target: Node3D, observer: Node3D) -> bool:
	if not is_instance_valid(target) or not target.is_inside_tree(): return false
	if not target.has_meta("in_stealth_grass"): return false
	if not target.get_meta("in_stealth_grass", false): return false
	
	# Flying units NEVER get stealth in grass
	if "Plane" in target.name or target.get("flight_height") != null or target.get("is_flying") == true or target.get("unit_attribute") == "Flying":
		return false
	if target.global_position.y > 4.5:
		return false
		
	# If target recently fired/attacked, it is temporarily revealed for retaliation
	if target.has_meta("stealth_revealed_timer"):
		if target.get_meta("stealth_revealed_timer", 0.0) > 0.0:
			return false
		
	# Friendly / same team check
	if observer != null and is_instance_valid(observer) and observer.is_inside_tree():
		var target_team = ""
		for g in target.get_groups():
			if g.begins_with("Side") or g == "Beast": target_team = g
		if target_team != "" and observer.is_in_group(target_team):
			return false
			
		# Close proximity face-to-face detection
		if target.global_position.distance_to(observer.global_position) <= 4.0:
			return false
			
		# Same stealth brush zone
		if observer.has_meta("current_brush_zone") and target.has_meta("current_brush_zone"):
			var obs_brush = observer.get_meta("current_brush_zone")
			var tgt_brush = target.get_meta("current_brush_zone")
			if obs_brush != null and obs_brush == tgt_brush and target.global_position.distance_to(observer.global_position) <= 7.0:
				return false
				
	return true

func get_distance_to_nearest_lane(pos: Vector3) -> float:
	if map_selected == "Arena_6P.tscn":
		var r = Vector2(pos.x, pos.z).length()
		if r < 18.0: return 0.0 # Central hub junction
		var ang = atan2(pos.z, pos.x)
		var lane_ang = round((ang - PI / 6.0) / (PI / 3.0)) * (PI / 3.0) + (PI / 6.0)
		var dir = Vector3(cos(lane_ang), 0, sin(lane_ang))
		var proj = Vector3(pos.x, 0, pos.z).dot(dir)
		var closest = dir * max(0.0, proj)
		return Vector3(pos.x, 0, pos.z).distance_to(closest)
	elif map_selected == "Arena_4P.tscn":
		var r = Vector2(pos.x, pos.z).length()
		if r < 15.0: return 0.0 # Center
		return min(abs(pos.x), abs(pos.z))
	else: # Default 1v1 Arena
		return abs(pos.x)

func get_vector_towards_nearest_lane(pos: Vector3) -> Vector3:
	if map_selected == "Arena_6P.tscn":
		var r = Vector2(pos.x, pos.z).length()
		if r < 18.0: return Vector3.ZERO
		var ang = atan2(pos.z, pos.x)
		var lane_ang = round((ang - PI / 6.0) / (PI / 3.0)) * (PI / 3.0) + (PI / 6.0)
		var dir = Vector3(cos(lane_ang), 0, sin(lane_ang))
		var proj = Vector3(pos.x, 0, pos.z).dot(dir)
		var closest = dir * max(0.0, proj)
		var to_lane = closest - Vector3(pos.x, 0, pos.z)
		if to_lane.length_squared() > 0.01:
			return to_lane.normalized()
		return Vector3.ZERO
	elif map_selected == "Arena_4P.tscn":
		var r = Vector2(pos.x, pos.z).length()
		if r < 15.0: return Vector3.ZERO
		if abs(pos.x) < abs(pos.z):
			return Vector3(-sign(pos.x), 0, 0)
		else:
			return Vector3(0, 0, -sign(pos.z))
	else:
		return Vector3(-sign(pos.x), 0, 0)

