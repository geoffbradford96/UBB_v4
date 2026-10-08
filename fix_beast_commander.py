with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'r') as f:
    text = f.read()

old_beast = '''	elif ai_profile == "The Great Beast Speaker":
		for i in range(8):
			var opts = ["RimworlderGunner", "RimworlderMelee", "RimworlderMonstrous", "RimworlderMutant", "SkyBeetle", "SkyJellyfish", "StoneOctopus", "GiantSquid"]
			var card = load("res://Data/Cards/" + opts[randi() % opts.size()] + ".tres")
			deck.append(card)'''
            
new_beast = '''	elif ai_profile == "The Great Beast Speaker":
		deck.append(load("res://Data/Cards/GreatBeastSpeakerCard.tres"))
		for i in range(7):
			var opts = ["RimworlderGunner", "RimworlderMelee", "RimworlderMonstrous", "RimworlderMutant", "SkyBeetle", "SkyJellyfish", "StoneOctopus", "GiantSquid"]
			var card = load("res://Data/Cards/" + opts[randi() % opts.size()] + ".tres")
			deck.append(card)'''
            
text = text.replace(old_beast, new_beast)

with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'w') as f:
    f.write(text)
