import glob

scripts = ['d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'd:/Game Dev/UBB_v2/Scripts/Tank.gd', 'd:/Game Dev/UBB_v2/Scripts/Hero.gd', 'd:/Game Dev/UBB_v2/Scripts/Tower.gd']

for script in scripts:
    try:
        with open(script, 'r') as f:
            text = f.read()
        
        if 'add_to_group("Targetable")' not in text:
            # Find func _ready(): and inject right after it
            text = text.replace('func _ready():\n', 'func _ready():\n\tadd_to_group("Targetable")\n')
            
            with open(script, 'w') as f:
                f.write(text)
            print(f"Patched {script}")
    except Exception as e:
        print(f"Skipped {script} - {e}")
