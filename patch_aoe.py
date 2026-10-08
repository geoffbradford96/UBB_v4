with open('d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'r') as f:
    text = f.read()

old_logic = '''				var target_health = current_target.get_node_or_null("HealthComponent")
				if target_health:
					target_health.take_damage(attack_damage)
					var ap = get_node_or_null("AnimationPlayer")'''

new_logic = '''				var target_health = current_target.get_node_or_null("HealthComponent")
				if target_health:
					if "SkyJellyfish" in self.name or "StoneOctopus" in self.name:
						for node in get_tree().get_nodes_in_group("Targetable"):
							if not node.is_in_group(my_team) and is_instance_valid(node):
								if self.global_position.distance_to(node.global_position) <= attack_range + 2.0:
									var hp = node.get_node_or_null("HealthComponent")
									if hp: hp.take_damage(attack_damage)
					else:
						target_health.take_damage(attack_damage)
						
					var ap = get_node_or_null("AnimationPlayer")'''

text = text.replace(old_logic, new_logic)

with open('d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'w') as f:
    f.write(text)
