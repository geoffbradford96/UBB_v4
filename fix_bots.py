import re

with open("Scripts/ArenaManager.gd", "r") as f:
    text = f.read()

# Fix total_slots and teams_for_ai
old_bot = """    var is_4p = (GameState.current_mode == "LOCAL_SPLIT_4P" or GameState.map_selected == "Arena_4P.tscn")
    var total_slots = 4 if is_4p else 2
    var local_players = players.size()
    var start_bot_idx = local_players
    
    if GameState.current_mode == "AI_VS_AI":
        start_bot_idx = 0
        if players.size() > 0 and players[0].ui:
            players[0].ui.visible = false
    
    var teams = ["SideA", "SideB", "SideC", "SideD", "SideE", "SideF"]"""

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

with open("Scripts/ArenaManager.gd", "w") as f:
    f.write(text)

print("Fixed BotAI setup in ArenaManager")
