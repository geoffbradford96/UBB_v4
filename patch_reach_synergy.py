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
        
    if 'var base_speed: float' not in text:
        text = text.replace('func _ready():', 'var base_speed: float\nvar base_attack_speed: float\n\nfunc _ready():\n\tbase_speed = speed\n\tif "attack_speed" in self:\n\t\tbase_attack_speed = self.get("attack_speed")')

    # Add Reach Synergy inside separation loop
    old_sep = '''			var separation = Vector3.ZERO
			if unit_attribute == "Ethereal":'''
            
    new_sep = '''			var separation = Vector3.ZERO
			var reach_count = 0
			if unit_attribute == "Ethereal":'''
            
    text = text.replace(old_sep, new_sep)
    
    old_col = '''				if col != self and col.is_in_group(my_team) and col.get("unit_attribute") != "Ethereal":'''
    new_col = '''				if col != self and col.is_in_group(my_team):
					if "Reach" in self.name and "Reach" in col.name: reach_count += 1
					if col.get("unit_attribute") == "Ethereal": continue
'''
    text = text.replace(old_col, new_col)
    
    # Apply Synergy at the end of separation
    old_apply = '''			velocity += separation * speed * 2.0'''
    new_apply = '''			velocity += separation * speed * 2.0
			
			if "Reach" in self.name:
				var synergy = min(reach_count, 5) * 0.15 # Up to +75% speed and attack speed
				speed = base_speed * (1.0 + synergy)
				if "attack_speed" in self:
					self.set("attack_speed", base_attack_speed * (1.0 + synergy))'''
                    
    text = text.replace(old_apply, new_apply)
    
    with open(script, 'w') as f:
        f.write(text)

print("Injected Reach Synergy into all combat scripts")
