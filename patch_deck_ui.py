import os

def patch_army_gd():
    filepath = "Scripts/ArmyGathering.gd"
    with open(filepath, 'r') as f:
        text = f.read()
    
    # 1. Add onready vars for Background, Title, Trims
    if "var all_cards = []" in text:
        text = text.replace("var all_cards = []", """@onready var bg = $Background
@onready var title_label = $Title
@onready var trim_top = $GoldTrimTop
@onready var trim_bot = $GoldTrimBottom
var all_cards = []""")
        
    # 2. Fix the missing scroll container in right panel
    old_deck_grid = """	count_label = Label.new()
	count_label.text = "Units & Spells (0/5)"
	right_vbox.add_child(count_label)
	
	right_deck_grid = GridContainer.new()
	right_deck_grid.columns = 2
	right_deck_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(right_deck_grid)
	
	var save_btn = Button.new()"""
    
    new_deck_grid = """	count_label = Label.new()
	count_label.text = "Units & Spells (0/5)"
	right_vbox.add_child(count_label)
	
	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(right_scroll)
	
	right_deck_grid = GridContainer.new()
	right_deck_grid.columns = 2
	right_deck_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right_deck_grid)
	
	var save_btn = Button.new()"""
    text = text.replace(old_deck_grid, new_deck_grid)
    
    # 3. Update background / title in _on_tab_changed
    old_tab_changed = """func _on_tab_changed(tab_idx: int):
	current_tab = tab_idx
	for c in left_grid.get_children():"""
	
    new_tab_changed = """func _on_tab_changed(tab_idx: int):
	current_tab = tab_idx
	
	var faction_names = ["Dominion of Sol", "The Void Swarm", "The Rimworlders", "Pirate Kingdoms", "The Reach"]
	if tab_idx >= 0 and tab_idx < faction_names.size():
		if title_label: title_label.text = faction_names[tab_idx] + " - Army Gathering"
	
	if bg and trim_top and trim_bot:
		if tab_idx == 0: # Dominion
			bg.color = Color(0.05, 0.2, 0.4)
			trim_top.color = Color(0.8, 0.7, 0.2)
			trim_bot.color = Color(0.8, 0.7, 0.2)
		elif tab_idx == 1: # Void
			bg.color = Color(0.15, 0.0, 0.3)
			trim_top.color = Color(0.8, 0.1, 0.9)
			trim_bot.color = Color(0.8, 0.1, 0.9)
		elif tab_idx == 2: # Rimworlders
			bg.color = Color(0.1, 0.3, 0.1)
			trim_top.color = Color(0.2, 0.9, 0.4)
			trim_bot.color = Color(0.2, 0.9, 0.4)
		elif tab_idx == 3: # Pirates
			bg.color = Color(0.3, 0.15, 0.05)
			trim_top.color = Color(0.9, 0.4, 0.1)
			trim_bot.color = Color(0.9, 0.4, 0.1)
		elif tab_idx == 4: # Reach
			bg.color = Color(0.05, 0.15, 0.2)
			trim_top.color = Color(0.1, 0.8, 0.9)
			trim_bot.color = Color(0.1, 0.8, 0.9)
			
	for c in left_grid.get_children():"""
    
    text = text.replace(old_tab_changed, new_tab_changed)

    with open(filepath, 'w') as f:
        f.write(text)
    
    print("Patched ArmyGathering UI")

if __name__ == "__main__":
    patch_army_gd()
