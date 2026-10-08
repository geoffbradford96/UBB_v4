with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'r') as f:
    text = f.read()

text = text.replace('var profiles = ["Void Charcon", "Dominion Planet Commander", "Mixed Hordes of the Unknown Realm"]', 'var profiles = ["Void Charcon", "Dominion Planet Commander", "Mixed Hordes of the Unknown Realm", "The Great Beast Speaker"]')

text = text.replace('deck = generate_themed_deck("Dominion")', 'deck = generate_themed_deck("Dominion")\n\telif ai_profile == "The Great Beast Speaker":\n\t\tdeck = generate_themed_deck("Rimworlders")')

filter_logic = '''				var is_void = "Void" in clean_name
				var is_rimworlder = "Rimworlder" in clean_name or "Sky" in clean_name or "Stone" in clean_name or "Giant" in clean_name
				var is_dominion = not is_void and not is_rimworlder
				
				var valid = false
				if theme == "Void" and is_void: valid = true
				elif theme == "Dominion" and is_dominion: valid = true
				elif theme == "Rimworlders" and is_rimworlder: valid = true
				elif theme == "Random": valid = true'''

text = text.replace('''				var is_void = clean_name.begins_with("Void")
				
				var valid = false
				if theme == "Void" and is_void: valid = true
				elif theme == "Dominion" and not is_void: valid = true
				elif theme == "Random": valid = true''', filter_logic)

with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'w') as f:
    f.write(text)
