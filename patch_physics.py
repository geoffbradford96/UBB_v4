with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

# Remove unit.set_physics_process(false)
text = text.replace('if not multiplayer.is_server():\n                unit.set_physics_process(false)', '')

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)
