scripts = [
    'd:/Game Dev/UBB_v2/Scripts/Unit.gd',
    'd:/Game Dev/UBB_v2/Scripts/Tank.gd',
    'd:/Game Dev/UBB_v2/Scripts/Medic.gd',
    'd:/Game Dev/UBB_v2/Scripts/RepairMan.gd',
    'd:/Game Dev/UBB_v2/Scripts/Assassin.gd',
    'd:/Game Dev/UBB_v2/Scripts/HeroHunter.gd',
    'd:/Game Dev/UBB_v2/Scripts/Plane.gd',
    'd:/Game Dev/UBB_v2/Scripts/Sniper.gd'
]

for script in scripts:
    with open(script, 'r') as f:
        text = f.read()
        
    old_reach = '''				if "attack_speed" in self:
					self.set("attack_speed", base_attack_speed * (1.0 + synergy))'''
                    
    new_reach = '''				if "attack_speed" in self:
					self.set("attack_speed", base_attack_speed * (1.0 + synergy))
				var r_mesh = get_node_or_null("MeshInstance3D")
				if r_mesh:
					var target_scale = 1.0 + (synergy * 0.6)
					r_mesh.scale = r_mesh.scale.lerp(Vector3(target_scale, target_scale, target_scale), 0.1)'''
                    
    if 'r_mesh' not in text:
        text = text.replace(old_reach, new_reach)
        with open(script, 'w') as f:
            f.write(text)

with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'r') as f:
    text = f.read()

old_scrap_proc = '''	if scrap_heal_time > 0:
		scrap_heal_time -= delta
		heal(50.0 * delta)'''
        
new_scrap_proc = '''	if scrap_heal_time > 0:
		scrap_heal_time -= delta
		heal(50.0 * delta)
		var s_mesh = get_parent().get_node_or_null("MeshInstance3D")
		if s_mesh:
			var pulse = 1.0 + sin(scrap_heal_time * 15.0) * 0.2
			s_mesh.scale = Vector3(pulse, pulse, pulse)
	elif scrap_heal_time <= 0.0 and scrap_heal_time > -1.0:
		scrap_heal_time = -2.0
		var s_mesh = get_parent().get_node_or_null("MeshInstance3D")
		if s_mesh: s_mesh.scale = Vector3(1, 1, 1)'''
        
if 's_mesh' not in text:
    text = text.replace(old_scrap_proc, new_scrap_proc)
    
    # Add print statement to trigger
    old_trigger = '''func trigger_scrap_heal():
	scrap_heal_time = 2.0'''
    new_trigger = '''func trigger_scrap_heal():
	if scrap_heal_time <= 0: print(get_parent().name, " triggers SCRAP HEAL!")
	scrap_heal_time = 2.0'''
    text = text.replace(old_trigger, new_trigger)

    with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'w') as f:
        f.write(text)

print("Injected Visual Indicators for Abilities.")
