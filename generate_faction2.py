import os

os.makedirs('d:/Game Dev/UBB/Data/Cards', exist_ok=True)
os.makedirs('d:/Game Dev/UBB/Scenes/Units/VoidSwarm', exist_ok=True)

faction2_units = {
    'VoidOverlord': {'script': 'Hero.gd', 'color': 'Color(0.2, 0.0, 0.4, 1)', 'type': 'Commander', 'cost': '0.0', 'spawn_count': 1},
    'VoidCrawler': {'script': 'Unit.gd', 'color': 'Color(0.3, 0.1, 0.5, 1)', 'type': 'Unit', 'cost': '2.0', 'spawn_count': 4},
    'VoidSpitter': {'script': 'SupportingFire.gd', 'color': 'Color(0.4, 0.0, 0.6, 1)', 'type': 'Unit', 'cost': '3.0', 'spawn_count': 2},
    'VoidStalker': {'script': 'Assassin.gd', 'color': 'Color(0.1, 0.0, 0.2, 0.5)', 'type': 'Unit', 'cost': '4.0', 'spawn_count': 2},
    'VoidCorruptor': {'script': 'RepairMan.gd', 'color': 'Color(0.6, 0.2, 0.8, 1)', 'type': 'Unit', 'cost': '3.0', 'spawn_count': 1},
    'VoidMeteor': {'script': 'Spell.gd', 'color': 'Color(0.8, 0.0, 0.8, 0.8)', 'type': 'Spell', 'cost': '5.0', 'spawn_count': 1}
}

for name, data in faction2_units.items():
    scene_path = f'd:/Game Dev/UBB/Scenes/Units/VoidSwarm/{name}.tscn'
    
    if data['type'] == 'Spell':
        scene_text = f'''[gd_scene load_steps=5 format=3 uid="uid://void{name.lower()}"]
[ext_resource type="Script" path="res://Scripts/Spell.gd" id="1_script"]
[sub_resource type="SphereShape3D" id="SphereShape3D_1"]
radius = 10.0
[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_1"]
transparency = 1
albedo_color = {data['color']}
emission_enabled = true
emission = {data['color']}
emission_energy_multiplier = 3.0
[sub_resource type="SphereMesh" id="SphereMesh_1"]
material = SubResource("StandardMaterial3D_1")
radius = 10.0
height = 20.0
[node name="{name}" type="Area3D" groups=["Team1"]]
script = ExtResource("1_script")
[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("SphereShape3D_1")
[node name="MeshInstance3D" type="MeshInstance3D" parent="."]
mesh = SubResource("SphereMesh_1")
'''
    else:
        scene_text = f'''[gd_scene load_steps=6 format=3 uid="uid://void{name.lower()}"]
[ext_resource type="Script" path="res://Scripts/{data['script']}" id="1_script"]
[ext_resource type="Script" path="res://Scripts/HealthComponent.gd" id="2_health"]
[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_1"]
[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_1"]
{'transparency = 1' if '0.5)' in data['color'] else ''}
albedo_color = {data['color']}
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
'''
    with open(scene_path, 'w') as f:
        f.write(scene_text)
        
    card_path = f'd:/Game Dev/UBB/Data/Cards/{name}Card.tres'
    card_text = f'''[gd_resource type="Resource" script_class="CardData" load_steps=3 format=3 uid="uid://card{name.lower()}"]
[ext_resource type="Script" path="res://Scripts/CardData.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://void{name.lower()}" path="res://Scenes/Units/VoidSwarm/{name}.tscn" id="2_scene"]
[resource]
script = ExtResource("1_script")
card_name = "{name}"
card_type = "{data['type']}"
cost = {data['cost']}
is_spell = {'true' if data['type'] == 'Spell' else 'false'}
spawn_count = {data['spawn_count']}
unit_scene = ExtResource("2_scene")
'''
    with open(card_path, 'w') as f:
        f.write(card_text)

print('Faction 2 setup complete!')
