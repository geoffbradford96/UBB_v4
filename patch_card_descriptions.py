import os

dir_path = "d:/Game Dev/UBB_v2/Data/Cards/"
for file in os.listdir(dir_path):
    if not file.endswith(".tres"): continue
    
    with open(dir_path + file, "r") as f:
        text = f.read()
        
    desc = ""
    if "Scrap" in file:
        desc = "Faction: Scrap Pirates.\\nPassive: Scrap Heal - Gains massive HP regeneration for 2 seconds whenever any ally dies nearby."
        if "Melee" in file or "Ranged" in file:
            desc = "Spawns 5 units. " + desc
        if "Tank" in file:
            desc = "Explodes on death, dealing 50 AoE damage to enemies. " + desc
    elif "Reach" in file:
        desc = "Faction: Reach Pirates.\\nPassive: Swarm Synergy - Gains up to +75% Movement and Attack Speed based on the number of nearby Reach allies."
        if "Melee" in file or "Ranged" in file:
            desc = "Spawns 5 units. " + desc
            
    if desc != "":
        # Find description line and replace it
        lines = text.split('\n')
        for i, line in enumerate(lines):
            if line.startswith('description ='):
                lines[i] = f'description = "{desc}"'
        
        with open(dir_path + file, "w") as f:
            f.write('\n'.join(lines))

print("Updated Card Descriptions.")
