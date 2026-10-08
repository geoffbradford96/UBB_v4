with open('d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'r') as f:
    text = f.read()

text = text.replace('var separation = Vector3.ZERO', 'var separation = Vector3.ZERO\n\t\t\tif unit_attribute == "Ethereal":\n\t\t\t\tresults.clear()')
text = text.replace('if col != self and col.is_in_group(m_team):', 'if col != self and col.is_in_group(m_team) and col.get("unit_attribute") != "Ethereal":')

with open('d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'w') as f:
    f.write(text)
