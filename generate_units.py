import os

units = [
    {"name": "Commander", "cost": 0.0, "color": "1, 0, 0, 1"}, # Red
    {"name": "CheapGrunt", "cost": 2.0, "color": "0, 1, 0, 1"}, # Green
    {"name": "SupportingFire", "cost": 3.0, "color": "0, 0, 1, 1"}, # Blue
    {"name": "Medic", "cost": 4.0, "color": "1, 1, 1, 1"}, # White
    {"name": "RepairMan", "cost": 3.0, "color": "1, 1, 0, 1"}, # Yellow
    {"name": "CommandBay", "cost": 5.0, "color": "0.5, 0.5, 0.5, 1"}, # Grey
    {"name": "CallArtillery", "cost": 4.0, "color": "1, 0.5, 0, 1", "spell": True}, # Orange
    {"name": "Sniper", "cost": 5.0, "color": "0.5, 0, 0.5, 1"}, # Purple
    {"name": "HeroHunter", "cost": 4.0, "color": "1, 0.2, 0.5, 1"}, # Pink
    {"name": "Assassin", "cost": 6.0, "color": "0.1, 0.1, 0.1, 1"} # Black
]

tscn_template = """[gd_scene load_steps=6 format=3 uid="uid://{uid}"]

[ext_resource type="Script" path="res://Scripts/Unit.gd" id="1_script"]
[ext_resource type="Script" path="res://Scripts/HealthComponent.gd" id="2_health"]

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_1"]

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_1"]
albedo_color = Color({color})

[sub_resource type="CapsuleMesh" id="CapsuleMesh_1"]
material = SubResource("StandardMaterial3D_1")

[node name="{name}" type="CharacterBody3D" groups=["Team1"]]
script = ExtResource("1_script")

[node name="HealthComponent" type="Node" parent="."]
script = ExtResource("2_health")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("CapsuleShape3D_1")

[node name="MeshInstance3D" type="MeshInstance3D" parent="."]
mesh = SubResource("CapsuleMesh_1")

[node name="NavigationAgent3D" type="NavigationAgent3D" parent="."]
"""

tres_template = """[gd_resource type="Resource" script_class="CardData" load_steps=3 format=3 uid="uid://{card_uid}"]

[ext_resource type="Script" path="res://Scripts/CardData.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://{uid}" path="res://Scenes/Units/{name}.tscn" id="2_scene"]

[resource]
script = ExtResource("1_script")
card_name = "{display_name}"
cost = {cost}
is_spell = {is_spell}
unit_scene = ExtResource("2_scene")
"""

import uuid

# Make sure directories exist
os.makedirs("d:/Game Dev/UBB/Scenes/Units", exist_ok=True)
os.makedirs("d:/Game Dev/UBB/Data/Cards", exist_ok=True)

for i, unit in enumerate(units):
    base_uid = f"unit{i}abcd123"
    card_uid = f"card{i}abcd123"
    
    is_spell = "true" if unit.get("spell", False) else "false"
    
    # Generate TSCN
    tscn_content = tscn_template.format(uid=base_uid, name=unit["name"], color=unit["color"])
    with open(f"d:/Game Dev/UBB/Scenes/Units/{unit['name']}.tscn", "w") as f:
        f.write(tscn_content)
        
    # Generate TRES
    tres_content = tres_template.format(card_uid=card_uid, uid=base_uid, name=unit["name"], display_name=unit["name"], cost=unit["cost"], is_spell=is_spell)
    with open(f"d:/Game Dev/UBB/Data/Cards/{unit['name']}Card.tres", "w") as f:
        f.write(tres_content)

print("Generated all unit scenes and card data resources!")
