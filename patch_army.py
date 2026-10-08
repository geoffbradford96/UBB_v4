import re

with open("Scripts/ArmyGathering.gd", "r") as f:
    text = f.read()

# Add tabs
old_tabs = """	tab_bar.add_tab("Dominion of Sol")
	tab_bar.add_tab("The Void Swarm")
	tab_bar.add_tab("The Rimworlders")"""

new_tabs = """	tab_bar.add_tab("Dominion of Sol")
	tab_bar.add_tab("The Void Swarm")
	tab_bar.add_tab("The Rimworlders")
	tab_bar.add_tab("Pirate Kingdoms")
	tab_bar.add_tab("The Reach")"""

text = text.replace(old_tabs, new_tabs)

# Fix filtering
old_filter = """		var is_void = "Void" in card_data.card_name
		var is_rimworlder = "Rimworlder" in card_data.card_name or "Sky" in card_data.card_name or "Stone" in card_data.card_name or "Giant" in card_data.card_name or "Great" in card_data.card_name
		var is_dominion = not is_void and not is_rimworlder
		
		if (tab_idx == 0 and is_dominion) or (tab_idx == 1 and is_void) or (tab_idx == 2 and is_rimworlder):"""

new_filter = """		var is_void = "Void" in card_data.card_name
		var is_rimworlder = "Rimworlder" in card_data.card_name or "Sky" in card_data.card_name or "Stone" in card_data.card_name or "Giant" in card_data.card_name or "Great" in card_data.card_name
		var is_pirate = "Scrap" in card_data.card_name
		var is_reach = "Reach" in card_data.card_name
		var is_dominion = not is_void and not is_rimworlder and not is_pirate and not is_reach
		
		if (tab_idx == 0 and is_dominion) or (tab_idx == 1 and is_void) or (tab_idx == 2 and is_rimworlder) or (tab_idx == 3 and is_pirate) or (tab_idx == 4 and is_reach):"""

text = text.replace(old_filter, new_filter)

with open("Scripts/ArmyGathering.gd", "w") as f:
    f.write(text)

print("ArmyGathering tabs patched")
