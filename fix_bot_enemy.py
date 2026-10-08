import re

with open("Scripts/ArenaManager.gd", "r") as f:
    text = f.read()

text = re.sub(r'# Pick enemy team.*?(?=if GameState\.ai_difficulty)', '# Pick enemy team\n        bot.enemy_team = "SideB" if bot.my_team == "SideA" else "SideA"\n        \n        ', text, flags=re.DOTALL)

with open("Scripts/ArenaManager.gd", "w") as f:
    f.write(text)

print("Patched enemy_team logic")
