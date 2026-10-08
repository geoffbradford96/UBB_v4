with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

old_logic = '''    var teams = ["SideA", "SideB", "SideC", "SideD"]
    for i in range(start_bot_idx, total_slots):
        var bot = BotAI.new()'''

new_logic = '''    var teams = ["SideA", "SideB", "SideC", "SideD"]
    
    if GameState.current_mode.begins_with("ONLINE"):
        return # Do not spawn AIs in online PvP matches!
        
    for i in range(start_bot_idx, total_slots):
        var bot = BotAI.new()'''

text = text.replace(old_logic, new_logic)

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)
