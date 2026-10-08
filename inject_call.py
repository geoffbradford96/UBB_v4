with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

text = text.replace('add_child(timer)', 'add_child(timer)\n    _apply_faction_visuals()')

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)
