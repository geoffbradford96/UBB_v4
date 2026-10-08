import os

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

bot_logic = '''
    var is_4p = (GameState.current_mode == "LOCAL_SPLIT_4P" or GameState.map_selected == "Arena_4P.tscn")
    var total_slots = 4 if is_4p else 2
    var local_players = players.size()
    
    # Spawn BotAI for remaining empty slots!
    var teams = ["SideA", "SideB", "SideC", "SideD"]
    for i in range(local_players, total_slots):
        var bot = BotAI.new()
        bot.my_team = teams[i]
        
        # Pick enemy team (simplified: just first available enemy for target checking)
        if i == 0: bot.enemy_team = "SideB"
        elif i == 1: bot.enemy_team = "SideA"
        elif i == 2: bot.enemy_team = "SideA"
        elif i == 3: bot.enemy_team = "SideA"
        
        if GameState.ai_difficulty == "EASY": bot.requisition_rate = 0.3
        elif GameState.ai_difficulty == "MEDIUM": bot.requisition_rate = 0.5
        elif GameState.ai_difficulty == "HARD": bot.requisition_rate = 0.8
        
        add_child(bot)
        print("Spawned BotAI for ", bot.my_team)
'''

text = text.replace('setup_match():', 'setup_match():\n' + bot_logic)

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)
