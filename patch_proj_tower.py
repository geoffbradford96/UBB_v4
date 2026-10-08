with open('d:/Game Dev/UBB_v2/Scripts/Projectile.gd', 'r') as f:
    text = f.read()

text = text.replace('var target: Node3D = null', 'var target: Node3D = null\nvar is_poisonous: bool = false')
text = text.replace('health_node.take_damage(damage)', 'health_node.take_damage(damage)\n\t\t\tif is_poisonous:\n\t\t\t\thealth_node.apply_poison(4, damage * 0.5)')

with open('d:/Game Dev/UBB_v2/Scripts/Projectile.gd', 'w') as f:
    f.write(text)

with open('d:/Game Dev/UBB_v2/Scripts/Tower.gd', 'r') as f:
    text2 = f.read()

text2 = text2.replace('extends StaticBody3D', 'extends StaticBody3D\n\nvar faction: String = "Dominion"')
text2 = text2.replace('proj_inst.damage = attack_damage', 'if faction == "Rimworlders":\n\t\t\tproj_inst.damage = attack_damage * 0.4\n\t\t\tproj_inst.is_poisonous = true\n\t\telse:\n\t\t\tproj_inst.damage = attack_damage')

with open('d:/Game Dev/UBB_v2/Scripts/Tower.gd', 'w') as f:
    f.write(text2)
