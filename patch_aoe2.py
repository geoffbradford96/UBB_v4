with open('d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'r') as f:
    text = f.read()

old_logic = '''					if "SkyJellyfish" in self.name or "StoneOctopus" in self.name:
						for node in get_tree().get_nodes_in_group("Targetable"):
							if not node.is_in_group(my_team) and is_instance_valid(node):'''

new_logic = '''					if "SkyJellyfish" in self.name or "StoneOctopus" in self.name:
						var m_team = ""
						for g in get_groups():
							if g.begins_with("Side"): m_team = g
						for node in get_tree().get_nodes_in_group("Targetable"):
							if not node.is_in_group(m_team) and is_instance_valid(node):'''

text = text.replace(old_logic, new_logic)

with open('d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'w') as f:
    f.write(text)
