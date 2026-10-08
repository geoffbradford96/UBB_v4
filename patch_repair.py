with open('d:/Game Dev/UBB_v2/Scripts/RepairMan.gd', 'r') as f:
    text = f.read()

text = text.replace('if "Tower" in a.name or "Base" in a.name or "CommandBay" in a.name:', 'if "Tower" in a.name or "Base" in a.name or "CommandBay" in a.name or a.get("unit_attribute") == "Mechanical":')
text = text.replace('if "Base" in current_target.name:', 'if current_target.get("unit_attribute") == "Mechanical":\n\t\t\teffective_range += 2.0\n\t\telif "Base" in current_target.name:')

with open('d:/Game Dev/UBB_v2/Scripts/RepairMan.gd', 'w') as f:
    f.write(text)
