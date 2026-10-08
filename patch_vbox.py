with open("Scripts/ArmyGathering.gd", "r") as f:
    text = f.read()

text = text.replace("var right_vbox = VBoxContainer.new()\n\tright_panel.add_child(right_vbox)", "var right_vbox = VBoxContainer.new()\n\tright_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL\n\tright_panel.add_child(right_vbox)")

with open("Scripts/ArmyGathering.gd", "w") as f:
    f.write(text)
