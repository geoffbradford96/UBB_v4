with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

text = text.replace('@export var max_requisition: float = 10.0', '@export var max_requisition: float = 100.0')

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)

with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'r') as f:
    text = f.read()

text = text.replace('@export var max_requisition: float = 10.0', '@export var max_requisition: float = 100.0')

with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'w') as f:
    f.write(text)

print("Fixed max_requisition caps")
