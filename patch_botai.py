import re

def patch_bot_ai():
    filepath = "Scripts/BotAI.gd"
    with open(filepath, 'r') as f:
        text = f.read()
        
    old_ready = """	if ai_profile == "Void Charcon":
		deck = generate_themed_deck("Void")
	elif ai_profile == "Dominion Planet Commander":
		deck = generate_themed_deck("Dominion")
	elif ai_profile == "The Great Beast Speaker":
		deck = generate_themed_deck("Rimworlders")
	else:
		deck = generate_themed_deck("Random")"""
        
    new_ready = """	if ai_profile == "Void Charcon":
		deck = generate_themed_deck("Void")
	elif ai_profile == "Dominion Planet Commander":
		deck = generate_themed_deck("Dominion")
	elif ai_profile == "The Great Beast Speaker":
		deck = generate_themed_deck("Rimworlders")
	elif ai_profile == "The Scrap Pirate King":
		deck = generate_themed_deck("Pirates")
	elif ai_profile == "The Reach Queen":
		deck = generate_themed_deck("The Reach")
	else:
		deck = generate_themed_deck("Random")"""

    text = text.replace(old_ready, new_ready)
    
    old_theme = """				var is_void = "Void" in clean_name
				var is_rimworlder = "Rimworlder" in clean_name or "Sky" in clean_name or "Stone" in clean_name or "Giant" in clean_name or "GreatBeastSpeaker" in clean_name
				var is_dominion = not is_void and not is_rimworlder
				
				var valid = false
				if theme == "Void" and is_void: valid = true
				elif theme == "Dominion" and is_dominion: valid = true
				elif theme == "Rimworlders" and is_rimworlder: valid = true
				elif theme == "Random": valid = true"""
                
    new_theme = """				var is_void = "Void" in clean_name
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
				elif theme == "Random": valid = true"""
                
    text = text.replace(old_theme, new_theme)
    
    with open(filepath, 'w') as f:
        f.write(text)
        
    print("Patched BotAI")

if __name__ == "__main__":
    patch_bot_ai()
