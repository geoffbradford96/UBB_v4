import sys

with open("Scripts/ArenaManager.gd", "r") as f:
    text = f.read()

# 1. Update koth_points
text = text.replace('var koth_points = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0}', 'var koth_points = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0, "SideE": 0, "SideF": 0}')

# 2. Update human player config arrays
text = text.replace('var teams = ["SideA", "SideB", "SideC", "SideD"]', 'var teams = ["SideA", "SideB", "SideC", "SideD", "SideE", "SideF"]')
text = text.replace('var profiles = ["Player1", "Guest1", "Guest2", "Guest3"]', 'var profiles = ["Player1", "Guest1", "Guest2", "Guest3", "Guest4", "Guest5"]')

# 3. Update human UI loop bounds
text = text.replace('var is_4p = (GameState.current_mode == "LOCAL_SPLIT_4P")', 'var is_4p = (GameState.current_mode == "LOCAL_SPLIT_4P" or GameState.map_selected == "Arena_4P.tscn")\n        var is_6p = (GameState.map_selected == "Arena_6P.tscn")')
text = text.replace('var p_count = 4 if is_4p else 2', 'var p_count = 6 if is_6p else (4 if is_4p else 2)')
text = text.replace('var right_vbox = VBoxContainer.new() if is_4p else null', 'var right_vbox = VBoxContainer.new() if (is_4p or is_6p) else null')
text = text.replace('if is_4p:\n            right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL\n            h_box.add_child(right_vbox)', 'if is_4p or is_6p:\n            right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL\n            h_box.add_child(right_vbox)')
text = text.replace('if not is_4p: sub_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL', 'if not (is_4p or is_6p): sub_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL')
text = text.replace('if is_4p:\n                if i % 2 == 0: left_vbox.add_child(sub_c)\n                else: right_vbox.add_child(sub_c)', 'if is_4p or is_6p:\n                if i % 2 == 0: left_vbox.add_child(sub_c)\n                else: right_vbox.add_child(sub_c)')

# Fix teams array based on map inside human loop
# Wait, for 3v3 KOTH, humans playing should be properly split into SideA and SideB.
text = text.replace('pstate.team = teams[i]', 'pstate.team = "SideB" if (is_6p and i >= 3) else ("SideA" if is_6p else teams[i])')

# 4. Update Bot logic below the human setup loop
old_bot = """    var is_4p = (GameState.current_mode == "LOCAL_SPLIT_4P" or GameState.map_selected == "Arena_4P.tscn")
    var total_slots = 4 if is_4p else 2
    var local_players = players.size()
    var start_bot_idx = local_players
    
    if GameState.current_mode == "AI_VS_AI":
        start_bot_idx = 0
        if players.size() > 0 and players[0].ui:
            players[0].ui.visible = false
    
    var teams = ["SideA", "SideB", "SideC", "SideD"]"""

new_bot = """    var is_4p_mode = (GameState.current_mode == "LOCAL_SPLIT_4P" or GameState.map_selected == "Arena_4P.tscn")
    var is_6p_mode = (GameState.map_selected == "Arena_6P.tscn")
    var total_slots = 6 if is_6p_mode else (4 if is_4p_mode else 2)
    var local_players = players.size()
    var start_bot_idx = local_players
    
    if GameState.current_mode == "AI_VS_AI":
        start_bot_idx = 0
        if players.size() > 0 and players[0].ui:
            players[0].ui.visible = false
    
    var teams_for_ai = []
    if is_6p_mode:
        teams_for_ai = ["SideA", "SideA", "SideA", "SideB", "SideB", "SideB"]
    elif is_4p_mode:
        teams_for_ai = ["SideA", "SideB", "SideC", "SideD"]
    else:
        teams_for_ai = ["SideA", "SideB"]"""
        
text = text.replace(old_bot, new_bot)

# Replace bot assignment
text = text.replace('bot.my_team = teams[i]', 'bot.my_team = teams_for_ai[i]')

enemy_logic_old = """        # Pick enemy team (simplified: just first available enemy for target checking)
        if i == 0: bot.enemy_team = "SideB"
        elif i == 1: bot.enemy_team = "SideA"
        elif i == 2: bot.enemy_team = "SideA"
        elif i == 3: bot.enemy_team = "SideA" """
enemy_logic_new = """        # Pick enemy team
        bot.enemy_team = "SideB" if bot.my_team == "SideA" else "SideA" """
text = text.replace(enemy_logic_old, enemy_logic_new)

# Fix KOTH tick parsing for 6 players
old_koth = """    var team_counts = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0}
    for b in bodies:
        if b.is_in_group("Targetable") and not "Base" in b.name and not "Tower" in b.name:
            if b.is_in_group("SideA"): team_counts["SideA"] += 1
            elif b.is_in_group("SideB"): team_counts["SideB"] += 1
            elif b.is_in_group("SideC"): team_counts["SideC"] += 1
            elif b.is_in_group("SideD"): team_counts["SideD"] += 1"""
new_koth = """    var team_counts = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0, "SideE": 0, "SideF": 0}
    for b in bodies:
        if b.is_in_group("Targetable") and not "Base" in b.name and not "Tower" in b.name:
            if b.is_in_group("SideA"): team_counts["SideA"] += 1
            elif b.is_in_group("SideB"): team_counts["SideB"] += 1
            elif b.is_in_group("SideC"): team_counts["SideC"] += 1
            elif b.is_in_group("SideD"): team_counts["SideD"] += 1
            elif b.is_in_group("SideE"): team_counts["SideE"] += 1
            elif b.is_in_group("SideF"): team_counts["SideF"] += 1"""
text = text.replace(old_koth, new_koth)

# Also fix KotH_Zone
text = text.replace('get_node_or_null("KotH_Zone")', 'get_node_or_null("KotH_Zone")') # no-op just to be sure it's KotH_Zone, wait the scene has KotH_Zone

with open("Scripts/ArenaManager.gd", "w") as f:
    f.write(text)

print("ArenaManager.gd restored and patched successfully.")
