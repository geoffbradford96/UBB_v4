import re
import os

def patch_file(filepath):
    with open(filepath, 'r') as f:
        text = f.read()

    if '@onready var mesh' in text:
        text = re.sub(r'@onready var mesh(\s*:\s*\w+)?\s*=\s*\$MeshInstance3D', 'var mesh: Node3D', text)
        
        # Inject finding the mesh into _ready
        if 'func _ready():' in text:
            ready_inject = """func _ready():
	mesh = get_node_or_null("MeshInstance3D")
	if not mesh: mesh = get_node_or_null("VisualPivot")
	if not mesh: mesh = get_node_or_null("Visuals")
	if not mesh: mesh = self # fallback"""
            text = text.replace('func _ready():', ready_inject)
        else:
            ready_inject = """func _ready():
	mesh = get_node_or_null("MeshInstance3D")
	if not mesh: mesh = get_node_or_null("VisualPivot")
	if not mesh: mesh = get_node_or_null("Visuals")
	if not mesh: mesh = self # fallback\n"""
            # insert before _process or _physics_process
            if 'func _physics_process' in text:
                text = text.replace('func _physics_process', ready_inject + 'func _physics_process')
            elif 'func _process' in text:
                text = text.replace('func _process', ready_inject + 'func _process')
                
        with open(filepath, 'w') as f:
            f.write(text)
        print(f"Patched {filepath}")

def main():
    script_dir = "Scripts"
    for f in os.listdir(script_dir):
        if f.endswith(".gd"):
            patch_file(os.path.join(script_dir, f))

if __name__ == "__main__":
    main()
