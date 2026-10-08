import re

with open("Scripts/ArenaManager.gd", "r") as f:
    text = f.read()

# Add initial_towers dictionary
text = text.replace('var koth_points = ', 'var initial_towers_per_team = {}\nvar koth_points = ')

# Populate it at the end of _ready
ready_end = """    if GameState.game_mode == "KOTH":
        var timer = Timer.new()
        timer.wait_time = 1.0
        timer.autostart = true
        timer.connect("timeout", Callable(self, "_on_koth_tick"))
        add_child(timer)
    _apply_faction_visuals()"""

new_ready_end = """    if GameState.game_mode == "KOTH":
        var timer = Timer.new()
        timer.wait_time = 1.0
        timer.autostart = true
        timer.connect("timeout", Callable(self, "_on_koth_tick"))
        add_child(timer)
    _apply_faction_visuals()
    
    for t in ["SideA", "SideB", "SideC", "SideD", "SideE", "SideF"]:
        var count = 0
        for z in get_tree().get_nodes_in_group(t):
            if "Tower" in z.name: count += 1
        initial_towers_per_team[t] = max(count, 2)"""

text = text.replace(ready_end, new_ready_end)

# Fix formula
old_process = """        var dynamic_rate = requisition_rate + ((2 - player_towers) * 0.5)"""
new_process = """        var initial = initial_towers_per_team.get(p.team, 2)
        var dynamic_rate = requisition_rate + ((initial - player_towers) * (1.0 / initial))"""
text = text.replace(old_process, new_process)

with open("Scripts/ArenaManager.gd", "w") as f:
    f.write(text)
print("Patched requisition formula")
