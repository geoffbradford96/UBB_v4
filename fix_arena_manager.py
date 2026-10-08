with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

text = text.replace('\t\t\t\t\t\tif result:', '\t\t\tif result:')

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)
