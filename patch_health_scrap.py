with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'r') as f:
    text = f.read()

# Add scrap_heal_time
if 'var scrap_heal_time: float = 0.0' not in text:
    text = text.replace('var poison_timer: float = 0.0', 'var poison_timer: float = 0.0\nvar scrap_heal_time: float = 0.0')

# Add trigger_scrap_heal
if 'func trigger_scrap_heal():' not in text:
    text += '''

func trigger_scrap_heal():
	scrap_heal_time = 2.0
'''

# Process scrap_heal_time in _process
if 'scrap_heal_time > 0:' not in text:
    proc = '''	if poison_ticks > 0:'''
    new_proc = '''	if scrap_heal_time > 0:
		scrap_heal_time -= delta
		heal(50.0 * delta)
		
	if poison_ticks > 0:'''
    text = text.replace(proc, new_proc)

# Add die() logic
die_logic = '''func die():
	# SCRAP TANK EXPLOSION
	if "ScrapTank" in get_parent().name:
		for e in get_tree().get_nodes_in_group("Targetable"):
			if e != get_parent() and is_instance_valid(e) and global_position.distance_to(e.global_position) < 4.0:
				# Don't explode on own team!
				var explode = true
				for g in get_parent().get_groups():
					if g.begins_with("Side") and e.is_in_group(g): explode = false
				if explode:
					var hp = e.get_node_or_null("HealthComponent")
					if hp: hp.take_damage(50.0)

	# SCRAP HEAL TRIGGER
	var my_t = ""
	for g in get_parent().get_groups():
		if g.begins_with("Side"): my_t = g
	if my_t != "":
		for a in get_tree().get_nodes_in_group(my_t):
			if a != get_parent() and is_instance_valid(a) and "Scrap" in a.name and global_position.distance_to(a.global_position) < 5.0:
				var hp = a.get_node_or_null("HealthComponent")
				if hp and hp.has_method("trigger_scrap_heal"): hp.trigger_scrap_heal()

	print(get_parent().name, " was destroyed!")'''

text = text.replace('func die():\n\tprint(get_parent().name, " was destroyed!")', die_logic)

with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'w') as f:
    f.write(text)
