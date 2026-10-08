import re

with open("Scripts/ArenaManager.gd", "r") as f:
    text = f.read()

# Fix koth points
text = text.replace('var koth_points = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0}', 'var koth_points = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0, "SideE": 0, "SideF": 0}')

# Fix team counts in _on_koth_tick
old_koth = """    var team_counts = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0}
    for b in bodies:
        if b.is_in_group("Targetable") and not "Base" in b.name and not "Tower" in b.name:
            if b.is_in_group("SideA"): team_counts["SideA"] += 1
            elif b.is_in_group("SideB"): team_counts["SideB"] += 1
            elif b.is_in_group("SideC"): team_counts["SideC"] += 1
            elif b.is_in_group("SideD"): team_counts["SideD"] += 1"""
new_koth = """    var team_counts = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0, "SideE": 0, "SideF": 0}
    for b in bodies:
        if b.is_in_group("Targetable") and not "Base" in b.name and not "Tower" in b.name:
            if b.is_in_group("SideA"): team_counts["SideA"] += 1
            elif b.is_in_group("SideB"): team_counts["SideB"] += 1
            elif b.is_in_group("SideC"): team_counts["SideC"] += 1
            elif b.is_in_group("SideD"): team_counts["SideD"] += 1
            elif b.is_in_group("SideE"): team_counts["SideE"] += 1
            elif b.is_in_group("SideF"): team_counts["SideF"] += 1"""
text = text.replace(old_koth, new_koth)

with open("Scripts/ArenaManager.gd", "w") as f:
    f.write(text)

with open("Scenes/Arena_6P.tscn", "r") as f:
    tscn = f.read()

tscn = tscn.replace('''[node name="KOTH_Center" type="CSGCylinder3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 0)
radius = 20.0
height = 0.2
sides = 32''', '''[node name="KotH_Zone" type="Area3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)

[node name="CollisionShape3D" type="CollisionShape3D" parent="KotH_Zone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.5, 0)
shape = SubResource("CylinderShape3D_koth")

[node name="CSGCylinder3D" type="CSGCylinder3D" parent="KotH_Zone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 0)
radius = 20.0
height = 0.2
sides = 32
''')

# Add CylinderShape3D_koth definition
sub_resource_koth = '''[sub_resource type="CylinderShape3D" id="CylinderShape3D_koth"]
radius = 20.0
height = 10.0

[node name="Arena_6P" type="Node3D"]'''
tscn = tscn.replace('[node name="Arena_6P" type="Node3D"]', sub_resource_koth)

with open("Scenes/Arena_6P.tscn", "w") as f:
    f.write(tscn)

print("Patched KOTH!")
