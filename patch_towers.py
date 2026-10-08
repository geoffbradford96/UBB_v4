scripts = [
    'd:/Game Dev/UBB_v2/Scripts/Tower.gd',
    'd:/Game Dev/UBB_v2/Scripts/CommandBay.gd'
]
for script in scripts:
    try:
        with open(script, 'r') as f:
            text = f.read()
        if '@export var unit_attribute: String = "Mechanical"' not in text:
            text = text.replace('extends StaticBody3D', 'extends StaticBody3D\n\n@export var unit_attribute: String = "Mechanical"')
            with open(script, 'w') as f:
                f.write(text)
    except: pass
