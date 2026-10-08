with open('d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'r') as f:
    text = f.read()

text = text.replace('if col != self and col.is_in_group(my_team):', 'if col != self and col.is_in_group(my_team) and col.get("unit_attribute") != "Ethereal":')

with open('d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'w') as f:
    f.write(text)
