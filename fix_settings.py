import re

with open("Scripts/SettingsMenu.gd", "r") as f:
    text = f.read()

text = text.replace("$VBoxContainer/HBoxRes/ResolutionDropdown", "$CenterContainer/VBoxContainer/HBoxRes/ResolutionDropdown")
text = text.replace("$VBoxContainer/HBoxFull/FullscreenCheck", "$CenterContainer/VBoxContainer/HBoxFull/FullscreenCheck")
text = text.replace("$VBoxContainer/HBoxVol/VolumeSlider", "$CenterContainer/VBoxContainer/HBoxVol/VolumeSlider")

with open("Scripts/SettingsMenu.gd", "w") as f:
    f.write(text)

print("Fixed SettingsMenu paths")
