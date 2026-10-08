import os
import re

scripts_dir = r"d:\Game Dev\UBB_v2\Scripts"

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
        
    original_content = content

    # Replace standard enemy finding
    pattern = re.compile(r'var enemy_group = "SideB" if self\.is_in_group\("SideA"\) else "SideA"\s*\n\s*var (enemies|targets) = get_tree\(\)\.get_nodes_in_group\(enemy_group\)')
    replacement = r'''var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
	var \1 = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if not node.is_in_group(my_team):
			\1.append(node)'''
    content = pattern.sub(replacement, content)

    # Replace friendly finding (Medic, RepairMan)
    pattern_friend = re.compile(r'var friendly_group = "SideA" if self\.is_in_group\("SideA"\) else "SideB"\s*\n\s*var (friends|allies) = get_tree\(\)\.get_nodes_in_group\(friendly_group\)')
    replacement_friend = r'''var my_team = ""
	for g in get_groups():
		if g.begins_with("Side"): my_team = g
	var \1 = []
	for node in get_tree().get_nodes_in_group("Targetable"):
		if node.is_in_group(my_team) and node != self:
			\1.append(node)'''
    content = pattern_friend.sub(replacement_friend, content)

    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for filename in os.listdir(scripts_dir):
    if filename.endswith(".gd"):
        process_file(os.path.join(scripts_dir, filename))
