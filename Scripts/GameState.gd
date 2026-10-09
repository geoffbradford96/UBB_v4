extends Node

var current_mode = "LOCAL"
var player_faction = "Dominion of Sol"

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
var match_player_count = 2
var sudden_death_timer = 600.0

func _ready():
	print("Global GameState is active!")
	load_decks()
	
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

func host_game():
	var error = peer.create_server(8910, match_player_count) 
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Hosting game on port 8910")
	else:
		print("Failed to host game: ", error)

func join_game(ip: String):
	var error = peer.create_client(ip, 8910)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Joining game at ", ip)
	else:
		print("Failed to join game: ", error)
