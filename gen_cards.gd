extends SceneTree

func _init():
	var cards = {
		"RocketInfantry": {"cost": 4.0, "is_spell": false, "spawn_count": 1, "max_hp": 150.0, "desc": "Anti-vehicle rocket soldier."},
		"LandMineInfantry": {"cost": 2.5, "is_spell": false, "spawn_count": 1, "max_hp": 120.0, "desc": "Drops explosive mines as he marches."},
		"BoxyWalker": {"cost": 5.0, "is_spell": false, "spawn_count": 1, "max_hp": 250.0, "desc": "Heavy mech with 4 rapid-fire guns."},
		"SpiderTank": {"cost": 6.5, "is_spell": false, "spawn_count": 1, "max_hp": 200.0, "desc": "Long range artillery spider mech."}
	}
	
	for c_name in cards.keys():
		var path = "res://Data/Cards/" + c_name + "Card.tres"
		if not ResourceLoader.exists(path):
			var card = load("res://Scripts/CardData.gd").new()
			card.card_name = c_name
			card.card_type = "Unit"
			card.cost = cards[c_name]["cost"]
			card.is_spell = cards[c_name]["is_spell"]
			card.spawn_count = cards[c_name]["spawn_count"]
			card.max_hp = cards[c_name]["max_hp"]
			card.description = cards[c_name]["desc"]
			card.unit_scene = load("res://Scenes/Units/" + c_name + ".tscn")
			
			ResourceSaver.save(card, path)
			print("Created ", path)
			
	quit()
