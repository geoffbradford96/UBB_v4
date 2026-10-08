with open("Scripts/MainMenu.gd", "r") as f:
    text = f.read()

text = text.replace('print("Opening Settings...")', 'get_tree().change_scene_to_file("res://Scenes/SettingsMenu.tscn")')

with open("Scripts/MainMenu.gd", "w") as f:
    f.write(text)

with open("Scripts/SettingsMenu.gd", "r") as f:
    text = f.read()

text = text.replace('res://Scenes/ModeHub.tscn', 'res://Scenes/MainMenu.tscn')

with open("Scripts/SettingsMenu.gd", "w") as f:
    f.write(text)
