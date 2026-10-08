import os

scripts = [
    'd:/Game Dev/UBB_v2/Scripts/Unit.gd',
    'd:/Game Dev/UBB_v2/Scripts/Tank.gd',
    'd:/Game Dev/UBB_v2/Scripts/Hero.gd'
]

for script in scripts:
    with open(script, 'r') as f:
        text = f.read()
    
    if '@export var unit_attribute: String = "Organic"' not in text:
        text = text.replace('extends CharacterBody3D', 'extends CharacterBody3D\n\n@export var unit_attribute: String = "Organic"')
        with open(script, 'w') as f:
            f.write(text)
            
print("Added unit_attribute to base scripts")
