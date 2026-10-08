with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'r') as f:
    text = f.read()

# Add profiles to the exported enum dropdown
if 'The Scrap Pirate King' not in text:
    text = text.replace('export_enum("Void Charcon", "Dominion Planet Commander", "The Great Beast Speaker", "Mixed Hordes of the Unknown Realm")', 'export_enum("Void Charcon", "Dominion Planet Commander", "The Great Beast Speaker", "The Scrap Pirate King", "The Reach Queen", "Mixed Hordes of the Unknown Realm")')
    
# Generate Decks
new_decks = '''	elif ai_profile == "The Great Beast Speaker":
		for i in range(8):
			var opts = ["RimworlderGunner", "RimworlderMelee", "RimworlderMonstrous", "RimworlderMutant", "SkyBeetle", "SkyJellyfish", "StoneOctopus", "GiantSquid"]
			var card = load("res://Data/Cards/" + opts[randi() % opts.size()] + ".tres")
			deck.append(card)
	elif ai_profile == "The Scrap Pirate King":
		for i in range(8):
			var opts = ["ScrapMelee", "ScrapRanged", "ScrapTank", "ScrapPlane", "ScrapHunter", "ScrapRepair"]
			var card = load("res://Data/Cards/" + opts[randi() % opts.size()] + ".tres")
			deck.append(card)
	elif ai_profile == "The Reach Queen":
		for i in range(8):
			var opts = ["ReachMelee", "ReachRanged", "ReachTank", "ReachPlane", "ReachHunter", "ReachRepair"]
			var card = load("res://Data/Cards/" + opts[randi() % opts.size()] + ".tres")
			deck.append(card)'''
            
text = text.replace('''	elif ai_profile == "The Great Beast Speaker":
		for i in range(8):
			var opts = ["RimworlderGunner", "RimworlderMelee", "RimworlderMonstrous", "RimworlderMutant", "SkyBeetle", "SkyJellyfish", "StoneOctopus", "GiantSquid"]
			var card = load("res://Data/Cards/" + opts[randi() % opts.size()] + ".tres")
			deck.append(card)''', new_decks)

with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'w') as f:
    f.write(text)
