with open('d:/Game Dev/UBB_v2/Scripts/LandMine.gd', 'r') as f:
    text = f.read()

text = text.replace('if body.has_method("get_groups") and not body.is_in_group(friendly_group):', 'if body.get("unit_attribute") == "Ethereal": return\n\tif body.has_method("get_groups") and not body.is_in_group(friendly_group):')

with open('d:/Game Dev/UBB_v2/Scripts/LandMine.gd', 'w') as f:
    f.write(text)
