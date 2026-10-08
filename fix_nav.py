import os
import re

for f in os.listdir("Scripts"):
    if not f.endswith(".gd"): continue
    filepath = os.path.join("Scripts", f)
    with open(filepath, "r") as file:
        text = file.read()
    if "nav_agent" in text:
        text = re.sub(r'@onready var nav_agent[^=\n]*= \$NavigationAgent3D\n?', '', text)
        with open(filepath, "w") as file:
            file.write(text)
print("Removed unused nav_agent")
