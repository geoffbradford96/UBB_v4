with open('d:/Game Dev/UBB_v2/Scripts/ArmyGathering.gd', 'r') as f:
    text = f.read()

text = text.replace('tab_bar.add_tab("The Void Swarm")', 'tab_bar.add_tab("The Void Swarm")\n\ttab_bar.add_tab("The Rimworlders")')

filter_logic = '''
	for card_data in all_cards:
		var is_void = "Void" in card_data.card_name
		var is_rimworlder = "Rimworlder" in card_data.card_name or "Sky" in card_data.card_name or "Stone" in card_data.card_name or "Giant" in card_data.card_name
		var is_dominion = not is_void and not is_rimworlder
		
		if (tab_idx == 0 and is_dominion) or (tab_idx == 1 and is_void) or (tab_idx == 2 and is_rimworlder):
'''

text = text.replace('''	for card_data in all_cards:
		var is_void = "Void" in card_data.card_name
		if (tab_idx == 0 and not is_void) or (tab_idx == 1 and is_void):''', filter_logic)

with open('d:/Game Dev/UBB_v2/Scripts/ArmyGathering.gd', 'w') as f:
    f.write(text)
