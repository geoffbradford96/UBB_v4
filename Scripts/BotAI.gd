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
			
	# Dynamically accelerate thinking during Sudden Death or Heavy Defense
	var active_interval = think_interval
	var am_scene = get_tree().current_scene
	if am_scene and am_scene.get("sudden_death_active"):
		active_interval = min(active_interval, 0.55)
		
	think_timer += delta
	if think_timer >= active_interval:
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

func assess_threats() -> Dictionary:
	var am = get_tree().current_scene
	var is_sudden_death: bool = am.get("sudden_death_active") if am and "sudden_death_active" in am else false
	
	var my_structures = []
	var my_base: Node3D = null
	for s in get_tree().get_nodes_in_group(my_team):
		if "Base" in s.name or "Tower" in s.name or "CommandBay" in s.name:
			my_structures.append(s)
			if "Base" in s.name:
				my_base = s
				
	var all_hostiles = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if node != null and is_instance_valid(node) and not node.is_in_group(my_team):
			all_hostiles.append(node)
			
	var endangered_structure: Node3D = null
	var highest_threat_score: float = 0.0
	var closest_hostile: Node3D = null
	var hostiles_near_endangered: Array = []
	
	for s in my_structures:
		var threat_score = 0.0
		var s_health = s.get_node_or_null("HealthComponent")
		var health_pct = 1.0
		if s_health:
			health_pct = s_health.current_health / max(1.0, s_health.max_health)
			
		var is_base = "Base" in s.name
		var base_mult = 3.5 if is_base else 1.2
		
		# If damaged, significantly increase threat
		if health_pct < 0.98:
			threat_score += (1.0 - health_pct) * 60.0 * base_mult
			
		var close_hostiles = []
		for h in all_hostiles:
			var d = s.global_position.distance_to(h.global_position)
			if d <= 25.0:
				close_hostiles.append(h)
				var prox_factor = (25.0 - d) / 25.0
				var is_beast = h.is_in_group("Beast")
				var beast_mult = 1.6 if (is_beast and is_sudden_death) else 1.0
				threat_score += (18.0 * prox_factor * beast_mult) * base_mult
				
		if threat_score > highest_threat_score and not close_hostiles.is_empty():
			highest_threat_score = threat_score
			endangered_structure = s
			hostiles_near_endangered = close_hostiles
			var min_d = 9999.0
			for ch in close_hostiles:
				var cd = s.global_position.distance_to(ch.global_position)
				if cd < min_d:
					min_d = cd
					closest_hostile = ch
					
	return {
		"is_sudden_death": is_sudden_death,
		"threat_score": highest_threat_score,
		"endangered_structure": endangered_structure,
		"closest_hostile": closest_hostile,
		"hostiles_near_endangered": hostiles_near_endangered,
		"my_base": my_base,
		"structures": my_structures
	}

func evaluate_moves():
	var threat_info = assess_threats()
	
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
		
	# In emergency defense mode, prioritize spells and immediate affordable units!
	if threat_info.threat_score > 20.0:
		valid_hand.sort_custom(func(a, b):
			# Spells take high priority to wipe attacking clusters
			if a.is_spell and not b.is_spell: return true
			if not a.is_spell and b.is_spell: return false
			var a_afford = current_requisition >= a.cost
			var b_afford = current_requisition >= b.cost
			if a_afford and not b_afford: return true
			if not a_afford and b_afford: return false
			return a.cost > b.cost
		)
	else:
		# Standard priority: highest impact / cost first
		valid_hand.sort_custom(func(a, b): return a.cost > b.cost)
	
	for c in valid_hand:
		if current_requisition >= c.cost:
			var spawn_pos = calculate_optimal_spawn(c, threat_info)
			if spawn_pos != null:
				play_card(c, spawn_pos)
				# If under heavy attack and have energy, immediately deploy another defender!
				if threat_info.threat_score > 25.0 and current_requisition >= 10.0:
					continue
				if current_requisition < 15.0:
					break

func calculate_optimal_spawn(card: CardData, threat_info: Dictionary):
	# 1. Spell Targeting
	if card.is_spell:
		# If under attack, drop spell on the cluster attacking the endangered structure!
		if threat_info.threat_score > 10.0 and threat_info.hostiles_near_endangered.size() > 0:
			var best_spell_target = threat_info.hostiles_near_endangered[0]
			var max_cluster = 0
			for h in threat_info.hostiles_near_endangered:
				if not is_instance_valid(h): continue
				var count = 0
				for other in threat_info.hostiles_near_endangered:
					if is_instance_valid(other) and h.global_position.distance_to(other.global_position) < 10.0:
						count += 1
				if count > max_cluster:
					max_cluster = count
					best_spell_target = h
			return best_spell_target.global_position
			
		# Otherwise, find densest enemy cluster anywhere on the field
		var all_targets = []
		for u in get_tree().get_nodes_in_group("Targetable"):
			if not u.is_in_group(my_team) and not "Base" in u.name and not "Tower" in u.name and is_instance_valid(u):
				all_targets.append(u)
				
		if all_targets.size() > 0:
			var best_t = all_targets[0]
			var max_c = 0
			for u in all_targets:
				var c = 0
				for other in all_targets:
					if u.global_position.distance_to(other.global_position) < 10.0:
						c += 1
				if c > max_c:
					max_c = c
					best_t = u
			return best_t.global_position
		return null
		
	var my_structures = threat_info.structures
	if my_structures.is_empty():
		return null
		
	# 2. Defensive Interception Deployment when under threat
	if threat_info.threat_score > 12.0 and threat_info.endangered_structure != null:
		var anchor = threat_info.endangered_structure
		var target_pos = anchor.global_position
		
		if threat_info.closest_hostile != null and is_instance_valid(threat_info.closest_hostile):
			var to_threat = (threat_info.closest_hostile.global_position - anchor.global_position)
			to_threat.y = 0
			var threat_dist = to_threat.length()
			var threat_dir = to_threat.normalized() if threat_dist > 0.1 else Vector3(0, 0, 1)
			var side_dir = threat_dir.cross(Vector3.UP).normalized()
			
			# Ranged / Artillery / Sniper / Acid spitters deploy slightly offset / behind anchor
			if card.card_name in ["Sniper", "VoidSpitter", "SpiderTank", "ReachRanged", "RimworlderGunner", "BeastDigestiveCell"]:
				var offset_dist = clamp(threat_dist * 0.35, 4.0, 14.0)
				target_pos = anchor.global_position + (side_dir * (8.0 if randf() > 0.5 else -8.0)) + (threat_dir * offset_dist)
			else:
				# Melee / Tanks / Mechs / Interceptors deploy directly in front of the attacker to intercept!
				var intercept_dist = clamp(threat_dist * 0.65, 5.0, 22.0)
				target_pos = anchor.global_position + (threat_dir * intercept_dist) + (side_dir * randf_range(-3.0, 3.0))
		else:
			target_pos += Vector3(randf_range(-6.0, 6.0), 0, randf_range(-6.0, 6.0))
			
		# Clamp to valid deployment range (max 24.0m from anchor)
		if target_pos.distance_to(anchor.global_position) > 24.0:
			target_pos = anchor.global_position + (target_pos - anchor.global_position).normalized() * 24.0
		return target_pos
		
	# 3. Offense / Pushing Deployment (Standard or Sudden Death counter-attack)
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
	
	if card.card_name in ["Sniper", "VoidSpitter", "SpiderTank", "ReachRanged", "RimworlderGunner"]:
		var side_offset = right_dir * (18.0 if randf() > 0.5 else -18.0)
		target_pos += (push_dir * randf_range(3.0, 7.0)) + side_offset
	elif card.card_name in ["Assassin", "VoidStalker", "ReachHunter"]:
		var side_offset = right_dir * (14.0 if randf() > 0.5 else -14.0)
		target_pos += (push_dir * randf_range(8.0, 16.0)) + side_offset
	else:
		var side_offset = right_dir * randf_range(-5.0, 5.0)
		target_pos += (push_dir * randf_range(8.0, 18.0)) + side_offset
		
	# In Sudden Death: push further forward if territory is secure
	if threat_info.is_sudden_death:
		target_pos += push_dir * 4.0
		
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
