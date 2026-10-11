import os

arena = 'd:/Game Dev/UBB/Scenes/Arena.tscn'
with open(arena, 'r') as f:
    data = f.read()

if 'WorldEnvironment' not in data:
    env = """
[sub_resource type="ProceduralSkyMaterial" id="ProceduralSkyMaterial_1"]
sky_top_color = Color(0.2, 0.5, 0.8, 1)
sky_horizon_color = Color(0.6, 0.7, 0.8, 1)
ground_bottom_color = Color(0.1, 0.1, 0.1, 1)
ground_horizon_color = Color(0.6, 0.7, 0.8, 1)

[sub_resource type="Sky" id="Sky_1"]
sky_material = SubResource("ProceduralSkyMaterial_1")

[sub_resource type="Environment" id="Environment_1"]
background_mode = 2
sky = SubResource("Sky_1")
ambient_light_source = 3
ambient_light_color = Color(1, 1, 1, 1)
ambient_light_sky_contribution = 0.5
tonemap_mode = 2
glow_enabled = true
glow_bloom = 0.2
ssao_enabled = true

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_1")

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.707107, -0.5, 0.5, 0, 0.707107, 0.707107, -0.707107, -0.5, 0.5, 0, 100, 0)
shadow_enabled = true
shadow_bias = 0.05
directional_shadow_max_distance = 200.0
"""
    parts = data.split('\n[node name="Floor"', 1)
    if len(parts) > 1:
        new_data = parts[0] + env + '\n[node name="Floor"' + parts[1]
        with open(arena, 'w') as f:
            f.write(new_data)
        print('Added Environment to Arena')
