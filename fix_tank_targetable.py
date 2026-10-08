with open("Scripts/Tank.gd", "r") as f:
    text = f.read()

if 'add_to_group("Targetable")' not in text:
    text = text.replace("func _ready():", "func _ready():\n\tadd_to_group(\"Targetable\")")
    with open("Scripts/Tank.gd", "w") as f:
        f.write(text)
    print("Fixed Tank.gd targetable")
