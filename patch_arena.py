import re

with open("Scripts/ArenaManager.gd", "r") as f:
    text = f.read()

# Fix teams array for local setup loop
text = text.replace('var teams = ["SideA", "SideB", "SideC", "SideD"]', 'var teams = ["SideA", "SideB", "SideC", "SideD", "SideE", "SideF"]')
text = text.replace('var profiles = ["Player1", "Guest1", "Guest2", "Guest3"]', 'var profiles = ["Player1", "Guest1", "Guest2", "Guest3", "Guest4", "Guest5"]')

# Fix total_slots
slots_replacement = """    var is_4p = (GameState.current_mode == "LOCAL_SPLIT_4P" or GameState.map_selected == "Arena_4P.tscn")
    var is_6p = (GameState.map_selected == "Arena_6P.tscn")
    var total_slots = 6 if is_6p else (4 if is_4p else 2)
    var local_players = players.size()"""
text = re.sub(r'    var is_4p = .*?\n    var total_slots = .*?\n    var local_players = players.size\(\)', slots_replacement, text, flags=re.DOTALL)

# Fix teams depending on map (3v3 logic) for AI
teams_replacement = """    var teams_for_ai = []
    if is_6p:
        teams_for_ai = ["SideA", "SideA", "SideA", "SideB", "SideB", "SideB"]
    elif is_4p:
        teams_for_ai = ["SideA", "SideB", "SideC", "SideD"]
    else:
        teams_for_ai = ["SideA", "SideB"]
"""
text = text.replace('    var teams = ["SideA", "SideB", "SideC", "SideD", "SideE", "SideF"]\n    \n    if GameState.current_mode.begins_with', teams_replacement + '    if GameState.current_mode.begins_with')

# Update bot assignment
text = text.replace('bot.my_team = teams[i]', 'bot.my_team = teams_for_ai[i]')

enemy_logic_old = """        # Pick enemy team (simplified: just first available enemy for target checking)
        if i == 0: bot.enemy_team = "SideB"
        elif i == 1: bot.enemy_team = "SideA"
        elif i == 2: bot.enemy_team = "SideA"
        elif i == 3: bot.enemy_team = "SideA" """
enemy_logic_new = """        # Pick enemy team
        bot.enemy_team = "SideB" if bot.my_team == "SideA" else "SideA" """
text = text.replace(enemy_logic_old, enemy_logic_new)

with open("Scripts/ArenaManager.gd", "w") as f:
    f.write(text)

print("Patched ArenaManager.gd")
