import os

scripts = [
    'd:/Game Dev/UBB_v2/Scripts/Unit.gd',
    'd:/Game Dev/UBB_v2/Scripts/Tank.gd',
    'd:/Game Dev/UBB_v2/Scripts/Hero.gd'
]

logic = '''	# Dynamically assign attribute based on name if not set manually
	if "Tank" in name or "Walker" in name or "Plane" in name or "Tower" in name or "Base" in name or "CommandBay" in name:
		unit_attribute = "Mechanical"
	elif "Jellyfish" in name or "Beetle" in name or "Octopus" in name or "Squid" in name or "GreatBeastSpeaker" in name:
		unit_attribute = "Beast"
'''

for script in scripts:
    with open(script, 'r') as f:
        text = f.read()
    
    if "Dynamically assign attribute" not in text:
        text = text.replace('add_to_group("Targetable")', 'add_to_group("Targetable")\n\t' + logic)
        with open(script, 'w') as f:
            f.write(text)
            
print("Added dynamic attribute assignment!")
