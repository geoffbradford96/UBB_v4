import re

with open("Scripts/InGameUI.gd", "r") as f:
    text = f.read()

# Add player_id var
text = text.replace('var device_id: int = -1', 'var device_id: int = -1\nvar player_id: int = 1')

# Fix input logic
old_input = """	if input_mode == "CONTROLLER":
		if event.is_action_pressed("p1_prev_card"):
			selected_card_idx -= 1
			if selected_card_idx < 0: selected_card_idx = hand_container.get_child_count() - 1
			_update_controller_selection()
		elif event.is_action_pressed("p1_next_card"):
			selected_card_idx += 1
			if selected_card_idx >= hand_container.get_child_count(): selected_card_idx = 0
			_update_controller_selection()"""

new_input = """	if input_mode == "CONTROLLER":
		var prefix = "p" + str(player_id) + "_"
		if event.is_action_pressed(prefix + "prev_card"):
			selected_card_idx -= 1
			if selected_card_idx < 0: selected_card_idx = hand_container.get_child_count() - 1
			_update_controller_selection()
		elif event.is_action_pressed(prefix + "next_card"):
			selected_card_idx += 1
			if selected_card_idx >= hand_container.get_child_count(): selected_card_idx = 0
			_update_controller_selection()"""

text = text.replace(old_input, new_input)

with open("Scripts/InGameUI.gd", "w") as f:
    f.write(text)

with open("Scripts/ArenaManager.gd", "r") as f:
    arena = f.read()

arena = arena.replace('ui.player_profile = pstate.profile', 'ui.player_profile = pstate.profile\n            ui.player_id = pstate.p_id')

with open("Scripts/ArenaManager.gd", "w") as f:
    f.write(arena)

print("Patched InGameUI player_id")
