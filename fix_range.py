import glob, os
scripts = glob.glob('d:/Game Dev/UBB/Scripts/*.gd')
targets = ['Unit.gd', 'Hero.gd', 'RepairMan.gd', 'Assassin.gd']

for f in scripts:
    if os.path.basename(f) in targets:
        with open(f, 'r') as file:
            content = file.read()
            
        range_var = 'attack_range'
        if 'repair_range' in content:
            range_var = 'repair_range'
            
        search_str = f'if dist > {range_var}:'
        
        replacement = f'''var effective_range = {range_var}
\t\t\tif "Base" in current_target.name:
\t\t\t\teffective_range += 5.5
\t\t\telif "Tower" in current_target.name or "CommandBay" in current_target.name:
\t\t\t\teffective_range += 2.5
\t\t\tif dist > effective_range:'''
        
        if search_str in content:
            content = content.replace(search_str, replacement)
            with open(f, 'w') as file:
                file.write(content)
            print(f'Fixed collision blindspot in {os.path.basename(f)}')
