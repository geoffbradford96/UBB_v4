import math

header = """[gd_scene load_steps=16 format=3]

[ext_resource type="Script" path="res://Scripts/ArenaManager.gd" id="1_u5g0q"]
[ext_resource type="PackedScene" path="res://Scenes/InGameUI.tscn" id="2_rrg6c"]
[ext_resource type="Script" path="res://Scripts/InGameUI.gd" id="3_yw5vl"]
[ext_resource type="Script" path="res://Scripts/ArenaCamera.gd" id="4_qihlv"]
[ext_resource type="Script" path="res://Scripts/HealthComponent.gd" id="5_quofm"]
[ext_resource type="PackedScene" path="res://Scenes/Tower.tscn" id="6_y8d4a"]
[ext_resource type="Script" path="res://Scripts/Tower.gd" id="7_5hvej"]
[ext_resource type="PackedScene" path="res://Scenes/Projectile.tscn" id="8_c88e0"]

[sub_resource type="PlaneMesh" id="PlaneMesh_arena"]
size = Vector2(300, 300)

[sub_resource type="BoxShape3D" id="BoxShape3D_floor"]
size = Vector3(300, 0.1, 300)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_path"]
albedo_color = Color(0.35, 0.25, 0.15, 1)

[sub_resource type="PlaneMesh" id="PlaneMesh_path"]
material = SubResource("StandardMaterial3D_path")
size = Vector2(26, 120)

[sub_resource type="ProceduralSkyMaterial" id="ProceduralSkyMaterial_1"]
sky_top_color = Color(0.15, 0.1, 0.1, 1)
sky_horizon_color = Color(0.6, 0.3, 0.2, 1)
ground_bottom_color = Color(0.1, 0.1, 0.1, 1)
ground_horizon_color = Color(0.6, 0.3, 0.2, 1)

[sub_resource type="Sky" id="Sky_1"]
sky_material = SubResource("ProceduralSkyMaterial_1")

[sub_resource type="Environment" id="Environment_1"]
background_mode = 2
sky = SubResource("Sky_1")
ambient_light_source = 3
ambient_light_color = Color(1, 1, 1, 1)
ambient_light_sky_contribution = 0.5
tonemap_mode = 2
ssao_enabled = true
glow_enabled = true
glow_intensity = 1.5
glow_bloom = 0.2

[node name="Arena_6P" type="Node3D"]
script = ExtResource("1_u5g0q")

[node name="InGameUI" type="Control" parent="." instance=ExtResource("2_rrg6c")]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
script = ExtResource("3_yw5vl")

[node name="Ground" type="StaticBody3D" parent="."]

[node name="MeshInstance3D" type="MeshInstance3D" parent="Ground"]
mesh = SubResource("PlaneMesh_arena")

[node name="CollisionShape3D" type="CollisionShape3D" parent="Ground"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.05, 0)
shape = SubResource("BoxShape3D_floor")
"""

with open("Scenes/Arena_6P.tscn", "w") as f:
    f.write(header)
    
    # Generate 6 lanes/paths converging to center
    radius = 120.0
    for i in range(6):
        angle = i * (math.pi / 3.0)
        # Position path halfway to center
        px = (radius / 2.0) * math.sin(angle)
        pz = (radius / 2.0) * math.cos(angle)
        
        # Rotation Y needs to align with center
        # Since it's a plane, we rotate it around Y
        rot_y = angle
        
        # Godot transform matrix (approximate)
        sy = math.sin(rot_y)
        cy = math.cos(rot_y)
        
        f.write(f'''
[node name="Path{i}" type="MeshInstance3D" parent="Ground"]
transform = Transform3D({cy}, 0, {sy}, 0, 1, 0, {-sy}, 0, {cy}, {px}, 0.05, {pz})
mesh = SubResource("PlaneMesh_path")
''')

    f.write('''
[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_1")

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866025, -0.25, 0.433013, 0, 0.866025, 0.5, -0.5, -0.433013, 0.75, 0, 10, 0)
shadow_enabled = true
shadow_bias = 0.05
directional_shadow_max_distance = 300.0

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.5, 0.866025, 0, -0.866025, 0.5, 0, 30, 24)
current = true
script = ExtResource("4_qihlv")
''')

    # Add KOTH center marker
    f.write('''
[node name="KOTH_Center" type="CSGCylinder3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 0)
radius = 20.0
height = 0.2
sides = 32
''')

    # Generate 6 bases and towers
    # Team A: indices 0, 1, 2
    # Team B: indices 3, 4, 5
    for i in range(6):
        team = "SideA" if i < 3 else "SideB"
        angle = i * (math.pi / 3.0)
        bx = radius * math.sin(angle)
        bz = radius * math.cos(angle)
        
        # rotation to face center
        rot_y = angle + math.pi
        sy = math.sin(rot_y)
        cy = math.cos(rot_y)
        
        name = f"Base_{i}"
        f.write(f'''
[node name="{name}" type="CSGBox3D" parent="." groups=["{team}"]]
transform = Transform3D({cy}, 0, {sy}, 0, 1, 0, {-sy}, 0, {cy}, {bx}, 2.5, {bz})
use_collision = true
size = Vector3(10, 5, 10)

[node name="HealthComponent" type="Node" parent="{name}"]
script = ExtResource("5_quofm")
max_health = 2000.0
''')

        # Towers slightly in front and offset
        t_dist = radius - 30.0
        for side, offset in [("Left", -15.0), ("Right", 15.0)]:
            # calculate position of tower
            tx = t_dist * math.sin(angle) + offset * math.cos(angle)
            tz = t_dist * math.cos(angle) - offset * math.sin(angle)
            
            tname = f"Tower_{i}_{side}"
            f.write(f'''
[node name="{tname}" type="StaticBody3D" parent="." groups=["{team}"] instance=ExtResource("6_y8d4a")]
transform = Transform3D({cy}, 0, {sy}, 0, 1, 0, {-sy}, 0, {cy}, {tx}, 0, {tz})
script = ExtResource("7_5hvej")
projectile_scene = ExtResource("8_c88e0")
team = "{team}"
''')

print("Generated Arena_6P.tscn")
