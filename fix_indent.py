with open('d:/Game Dev/UBB_v2/Scripts/RepairMan.gd', 'r') as f:
    text = f.read()

text = text.replace('\t\t\t\t\t\t\t\tvar friendly_group = ""', '\t\t\t\tvar friendly_group = ""')

with open('d:/Game Dev/UBB_v2/Scripts/RepairMan.gd', 'w') as f:
    f.write(text)
