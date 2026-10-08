import os
import re

def patch_reach_synergy(filepath):
    with open(filepath, 'r') as f:
        text = f.read()

    # Skip if already patched or doesn't have _physics_process
    if "# Reach Synergy Inject" in text or "func _physics_process" not in text:
        return

    # Add base variables if not present
    if "var base_speed" not in text:
        text = text.replace("func _ready():", "var base_speed: float\nvar base_attack_val: float\n\nfunc _ready():")
        
        # Init base variables
        ready_init = """func _ready():
	base_speed = speed
	if "attack_speed" in self: base_attack_val = self.get("attack_speed")
	elif "attack_rate" in self: base_attack_val = self.get("attack_rate")"""
        text = text.replace("func _ready():", ready_init)

    # Inject synergy at top of _physics_process
    synergy_logic = """func _physics_process(delta):
	# Reach Synergy Inject
	var reach_count = 0
	if "Reach" in self.name:
		var my_team = ""
		for g in get_groups():
			if g.begins_with("Side"): my_team = g
		for node in get_tree().get_nodes_in_group(my_team):
			if node != self and "Reach" in node.name and global_position.distance_to(node.global_position) < 6.0:
				reach_count += 1
		var synergy = min(reach_count, 5) * 0.15
		speed = base_speed * (1.0 + synergy)
		if "attack_speed" in self: self.set("attack_speed", base_attack_val * (1.0 + synergy))
		elif "attack_rate" in self: self.set("attack_rate", base_attack_val / (1.0 + synergy))
		var r_mesh = get_node_or_null("MeshInstance3D")
		if not r_mesh: r_mesh = get_node_or_null("VisualPivot")
		if r_mesh: r_mesh.scale = r_mesh.scale.lerp(Vector3.ONE * (1.0 + (synergy * 0.6)), 0.1)
"""
    text = text.replace("func _physics_process(delta):", synergy_logic)

    # Ensure Targetable is added
    if 'add_to_group("Targetable")' not in text:
        text = text.replace("func _ready():", "func _ready():\n\tadd_to_group(\"Targetable\")")

    with open(filepath, 'w') as f:
        f.write(text)
    print(f"Patched Reach synergy into {filepath}")

def main():
    script_dir = "Scripts"
    targets = ["Plane.gd", "Hero.gd", "Sniper.gd", "HeroHunter.gd", "RepairMan.gd", "Assassin.gd", "Medic.gd"]
    for t in targets:
        path = os.path.join(script_dir, t)
        if os.path.exists(path):
            patch_reach_synergy(path)

if __name__ == "__main__":
    main()
