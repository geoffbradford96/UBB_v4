extends Node
class_name BotAI

@export var max_requisition: float = 100.0
var current_requisition: float = 0.0
var requisition_rate: float = 0.5

var deck: Array = []
var hand: Array = []
var discard: Array = []

var think_timer: float = 0.0
var think_interval: float = 1.0
var active_commander: Node3D = null

@export var my_team: String = "SideB"
@export var enemy_team: String = "SideA"

var profile: String = ""

func _ready():
	# If a profile was assigned (e.g. Player1, Guest1, etc.) and has a saved deck, load it!
	if profile != "" and GameState.player_decks.has(profile) and GameState.player_decks[profile].size() > 0:
		deck = GameState.player_decks[profile].duplicate()
		print(my_team + " BotAI initialized with deck from profile: " + profile)
	else:
		# Fallback: create a tailored 6-card deck (1 Commander + 5 Units/Spells)
		var theme = "Void"
		if my_team == "SideA": theme = "Dominion"
		elif "Guest2" in profile or "Rimworld" in profile: theme = "Rimworlders"
		elif "Guest3" in profile or "Pirate" in profile: theme = "Pirates"
		elif "Guest4" in profile or "Reach" in profile: theme = "The Reach"
		deck = generate_themed_deck(theme)
		print(my_team + " BotAI generated standard 6-card deck for faction: " + theme)
		
	deck.shuffle()
	# Draw starting hand of 3 cards (identical to player hand in HandContainer)
	draw_to_hand()
	draw_to_hand()
	draw_to_hand()

func _process(delta):
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			return # Let the server authority handle AI thinking in online matches!

	# Unified Requisition (Energy) generation: base rate + tower catchup bonus
	var bot_towers = 0
	for z in get_tree().get_nodes_in_group(my_team):
		if "Tower" in z.name:
			bot_towers += 1
	var am = get_tree().current_scene
	var initial = 2
	if am and am.get("initial_towers_per_team"):
		initial = am.initial_towers_per_team.get(my_team, 2)
		
	var dynamic_rate = requisition_rate + ((initial - bot_towers) * (1.0 / max(1.0, float(initial))))
	if current_requisition < max_requisition:
		current_requisition += dynamic_rate * delta
		if current_requisition > max_requisition:
			current_requisition = max_requisition
			
	think_timer += delta
	if think_timer >= think_interval:
		think_timer = 0.0
		evaluate_moves()

func draw_to_hand():
	if hand.size() >= 3:
		return
	if deck.is_empty():
		deck = discard.duplicate()
		discard.clear()
		deck.shuffle()
	
	if not deck.is_empty():
		var card_name = deck.pop_front()
		var data = load("res://Data/Cards/" + card_name + ".tres")
		if data:
			hand.append(data)

func evaluate_moves():
	var has_commander = false
	var my_units = get_tree().get_nodes_in_group(my_team)
	for u in my_units:
		if u.is_in_group("CommanderUnit") or "Commander" in u.name or "Overlord" in u.name or "GreatBeastSpeaker" in u.name:
			has_commander = true
			break

	var valid_hand = []
	for c in hand:
		if c.card_type == "Commander" and has_commander:
			continue
		valid_hand.append(c)
		
	if valid_hand.is_empty():
		return
	
	# Prioritize highest impact cards affordable with current energy
	valid_hand.sort_custom(func(a, b): return a.cost > b.cost)
	
	for c in valid_hand:
		if current_requisition >= c.cost:
			var spawn_pos = calculate_optimal_spawn(c)
			if spawn_pos != null:
				play_card(c, spawn_pos)
				# If AI still has sufficient energy, loop to potentially play another card
				if current_requisition < 15.0:
					break

func calculate_optimal_spawn(card: CardData):
	if card.is_spell:
		var all_targets = get_tree().get_nodes_in_group("Targetable")
		var valid_targets = []
		for u in all_targets:
			if not u.is_in_group(my_team) and not "Base" in u.name and not "Tower" in u.name:
				valid_targets.append(u)
				
		if valid_targets.size() > 0:
			var t = valid_targets.pick_random()
			return t.global_position
			
		return null
		
	var my_structures = []
	for z in get_tree().get_nodes_in_group(my_team):
		if "Base" in z.name or "Tower" in z.name or "CommandBay" in z.name:
			my_structures.append(z)
			
	if my_structures.is_empty():
		return null
		
	var spawn_anchor = my_structures[0]
	var center = Vector3(0, 0, 0)
	for s in my_structures:
		if s.global_position.distance_to(center) < spawn_anchor.global_position.distance_to(center):
			spawn_anchor = s
			
	var push_dir = (center - spawn_anchor.global_position).normalized()
	if push_dir.length() < 0.1:
		push_dir = Vector3(0, 0, 1)
		
	var right_dir = push_dir.cross(Vector3.UP).normalized()
	
	var target_pos = spawn_anchor.global_position
	if card.card_name == "Sniper" or card.card_name == "VoidSpitter" or card.card_name == "SpiderTank":
		var side_offset = right_dir * (20.0 if randf() > 0.5 else -20.0)
		target_pos += (push_dir * randf_range(2, 5)) + side_offset
	elif card.card_name == "Assassin" or card.card_name == "VoidStalker":
		var side_offset = right_dir * (15.0 if randf() > 0.5 else -15.0)
		target_pos += (push_dir * randf_range(5, 10)) + side_offset
	else:
		var side_offset = right_dir * randf_range(-5, 5)
		target_pos += (push_dir * randf_range(5, 15)) + side_offset
		
	# Clamp deployment to valid distance from friendly structure (max 24.0m, matching player's 25.0m rule)
	if target_pos.distance_to(spawn_anchor.global_position) > 24.0:
		target_pos = spawn_anchor.global_position + (target_pos - spawn_anchor.global_position).normalized() * 24.0
	return target_pos

func play_card(card: CardData, target_position: Vector3):
	current_requisition -= card.cost
	
	hand.erase(card)
	var file_name = card.resource_path.get_file().trim_suffix(".tres").trim_suffix(".remap")
	discard.append(file_name)
	
	print(my_team, " AI spent ", card.cost, " energy on ", card.card_name, " | Energy remaining: ", snapped(current_requisition, 0.1))
	
	var am = get_tree().current_scene
	if am and am.has_method("sync_spawn_card"):
		if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			am.rpc("sync_spawn_card", card.resource_path, target_position, my_team, str(randi()))
		else:
			am.sync_spawn_card(card.resource_path, target_position, my_team, str(randi()))
			
	draw_to_hand()

func generate_themed_deck(theme: String) -> Array:
	var dir = DirAccess.open("res://Data/Cards/")
	var pool_commanders = []
	var pool_units = []
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
				var clean_name = file_name.trim_suffix(".remap")
				var is_void = "Void" in clean_name
				var is_rimworlder = "Rimworlder" in clean_name or "Sky" in clean_name or "Stone" in clean_name or "Giant" in clean_name or "GreatBeastSpeaker" in clean_name
				var is_pirate = "Scrap" in clean_name
				var is_reach = "Reach" in clean_name
				var is_dominion = not is_void and not is_rimworlder and not is_pirate and not is_reach
				
				var valid = false
				if theme == "Void" and is_void: valid = true
				elif theme == "Dominion" and is_dominion: valid = true
				elif theme == "Rimworlders" and is_rimworlder: valid = true
				elif theme == "Pirates" and is_pirate: valid = true
				elif theme == "The Reach" and is_reach: valid = true
				elif theme == "Random": valid = true
				
				if valid:
					var res = load("res://Data/Cards/" + clean_name)
					if res != null:
						var raw_name = clean_name.replace(".tres", "")
						if "card_type" in res and res.card_type == "Commander":
							pool_commanders.append(raw_name)
						else:
							pool_units.append(raw_name)
			file_name = dir.get_next()
			
	var new_deck = []
	if pool_commanders.size() > 0:
		new_deck.append(pool_commanders.pick_random())
	
	pool_units.shuffle()
	# Pick exactly 5 units/spells to form standard 6-card deck
	for i in range(min(5, pool_units.size())):
		new_deck.append(pool_units[i])
		
	return new_deck
