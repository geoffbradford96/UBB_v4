import os

def patch(filepath):
    with open(filepath, 'r') as f:
        text = f.read()
    
    old_rmesh = 'var r_mesh = get_node_or_null("MeshInstance3D")'
    new_rmesh = """var r_mesh = get_node_or_null("MeshInstance3D")
				if not r_mesh: r_mesh = get_node_or_null("VisualPivot")"""
    
    if old_rmesh in text:
        text = text.replace(old_rmesh, new_rmesh)
        with open(filepath, 'w') as f:
            f.write(text)
        print(f"Patched {filepath}")

patch("Scripts/Tank.gd")
patch("Scripts/Unit.gd")
