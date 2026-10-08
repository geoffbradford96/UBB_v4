with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'r') as f:
    text = f.read()

# Fix profiles array
old_profiles = 'var profiles = ["Void Charcon", "Dominion Planet Commander", "Mixed Hordes of the Unknown Realm", "The Great Beast Speaker"]'
new_profiles = 'var profiles = ["Void Charcon", "Dominion Planet Commander", "Mixed Hordes of the Unknown Realm", "The Great Beast Speaker", "The Scrap Pirate King", "The Reach Queen"]'
text = text.replace(old_profiles, new_profiles)

# Fix commander spawning for Scrap
old_scrap = '''	elif ai_profile == "The Scrap Pirate King":
		for i in range(8):
			var opts = ["ScrapMelee", "ScrapRanged", "ScrapTank", "ScrapPlane", "ScrapHunter", "ScrapRepair"]
			var card = load("res://Data/Cards/" + opts[randi() % opts.size()] + ".tres")
			deck.append(card)'''
new_scrap = '''	elif ai_profile == "The Scrap Pirate King":
		deck.append(load("res://Data/Cards/ScrapCommander.tres"))
		for i in range(7):
			var opts = ["ScrapMelee", "ScrapRanged", "ScrapTank", "ScrapPlane", "ScrapHunter", "ScrapRepair"]
			var card = load("res://Data/Cards/" + opts[randi() % opts.size()] + ".tres")
			deck.append(card)'''
text = text.replace(old_scrap, new_scrap)

# Fix commander spawning for Reach
old_reach = '''	elif ai_profile == "The Reach Queen":
		for i in range(8):
			var opts = ["ReachMelee", "ReachRanged", "ReachTank", "ReachPlane", "ReachHunter", "ReachRepair"]
			var card = load("res://Data/Cards/" + opts[randi() % opts.size()] + ".tres")
			deck.append(card)'''
new_reach = '''	elif ai_profile == "The Reach Queen":
		deck.append(load("res://Data/Cards/ReachCommander.tres"))
		for i in range(7):
			var opts = ["ReachMelee", "ReachRanged", "ReachTank", "ReachPlane", "ReachHunter", "ReachRepair"]
			var card = load("res://Data/Cards/" + opts[randi() % opts.size()] + ".tres")
			deck.append(card)'''
text = text.replace(old_reach, new_reach)

with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'w') as f:
    f.write(text)
