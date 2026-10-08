with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

old_logic = '''    var local_players = players.size()
    
    # Spawn BotAI for remaining empty slots!
    var teams = ["SideA", "SideB", "SideC", "SideD"]
    for i in range(local_players, total_slots):'''

new_logic = '''    var local_players = players.size()
    var start_bot_idx = local_players
    
    if GameState.current_mode == "AI_VS_AI":
        start_bot_idx = 0
        if players.size() > 0 and players[0].ui:
            players[0].ui.visible = false
    
    var teams = ["SideA", "SideB", "SideC", "SideD"]
    for i in range(start_bot_idx, total_slots):'''

text = text.replace(old_logic, new_logic)

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)
