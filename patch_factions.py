import re

with open("Scripts/ArenaManager.gd", "r") as f:
    text = f.read()

old_get_team = """func _get_team_faction(team: String) -> String:
    for child in get_children():
        if child.has_method("get_class") and "BotAI" in child.get_script().resource_path:
            if child.my_team == team:
                if child.ai_profile == "Void Charcon": return "Void"
                if child.ai_profile == "The Great Beast Speaker": return "Rimworlders"
                if child.ai_profile == "Dominion Planet Commander": return "Dominion"
                var options = ["Dominion", "Void", "Rimworlders"]
                return options[randi() % options.size()]
    for p in players:
        if p.team == team:
            var deck = []
            if GameState.player_decks.has(p.profile):
                deck = GameState.player_decks[p.profile]
            var v = 0; var r = 0; var d = 0
            for c in deck:
                if "Void" in c: v += 1
                elif "Rimworlder" in c or "Sky" in c or "Stone" in c or "Giant" in c or "Great" in c: r += 1
                else: d += 1
            var mx = max(d, max(v, r))
            if mx == v and v > 0: return "Void"
            if mx == r and r > 0: return "Rimworlders"
            return "Dominion"
    var opts = ["Dominion", "Void", "Rimworlders"]
    return opts[randi() % opts.size()]"""

new_get_team = """func _get_team_faction(team: String) -> String:
    for child in get_children():
        if child.has_method("get_class") and "BotAI" in child.get_script().resource_path:
            if child.my_team == team:
                if child.ai_profile == "Void Charcon": return "Void"
                if child.ai_profile == "The Great Beast Speaker": return "Rimworlders"
                if child.ai_profile == "Dominion Planet Commander": return "Dominion"
                if child.ai_profile == "The Scrap Pirate King": return "Pirates"
                if child.ai_profile == "The Reach Queen": return "The Reach"
                var options = ["Dominion", "Void", "Rimworlders", "Pirates", "The Reach"]
                return options[randi() % options.size()]
    for p in players:
        if p.team == team:
            var deck = []
            if GameState.player_decks.has(p.profile):
                deck = GameState.player_decks[p.profile]
            var v = 0; var r = 0; var d = 0; var pi = 0; var reach = 0
            for c in deck:
                if "Void" in c: v += 1
                elif "Rimworlder" in c or "Sky" in c or "Stone" in c or "Giant" in c or "Great" in c: r += 1
                elif "Scrap" in c: pi += 1
                elif "Reach" in c: reach += 1
                else: d += 1
            var mx = max(d, max(v, max(r, max(pi, reach))))
            if mx == v and v > 0: return "Void"
            if mx == r and r > 0: return "Rimworlders"
            if mx == pi and pi > 0: return "Pirates"
            if mx == reach and reach > 0: return "The Reach"
            return "Dominion"
    var opts = ["Dominion", "Void", "Rimworlders", "Pirates", "The Reach"]
    return opts[randi() % opts.size()]"""

text = text.replace(old_get_team, new_get_team)

with open("Scripts/ArenaManager.gd", "w") as f:
    f.write(text)

print("ArenaManager faction generation patched")
