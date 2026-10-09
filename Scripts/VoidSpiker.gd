extends "res://Scripts/Unit.gd"

func _ready():
    super._ready()
    # Procedural mesh generation for VoidSpiker
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    self.mesh = mesh_node
    

    var mat_chitin = StandardMaterial3D.new()
    mat_chitin.albedo_color = Color(0.12, 0.02, 0.18)
    mat_chitin.metallic = 0.75
    mat_chitin.roughness = 0.2

    var mat_spikes = StandardMaterial3D.new()
    mat_spikes.albedo_color = Color(0.85, 0.1, 0.85)
    mat_spikes.emission_enabled = true
    mat_spikes.emission = Color(0.85, 0.1, 0.85)
    mat_spikes.emission_energy_multiplier = 3.5

    var mat_eyes = StandardMaterial3D.new()
    mat_eyes.albedo_color = Color(0.95, 0.0, 0.85)
    mat_eyes.emission_enabled = true
    mat_eyes.emission = Color(0.95, 0.0, 0.85)
    mat_eyes.emission_energy_multiplier = 2.5

    # Segmented Obsidian Carapace
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.radius = 1.2
    body.mesh.height = 3.8
    body.material_override = mat_chitin
    body.position.y = 1.4
    body.rotation_degrees.x = 90
    mesh_node.add_child(body)

    # Dorsal Crystalline Spines (2 Rows of 4 Razor Spines)
    for i in range(8):
        var side = -1.0 if (i % 2 == 0) else 1.0
        var row = float(int(i / 2.0))
        var spike = MeshInstance3D.new()
        spike.mesh = CylinderMesh.new()
        spike.mesh.top_radius = 0.02
        spike.mesh.bottom_radius = 0.22
        spike.mesh.height = 1.8 + (1.5 - abs(row - 1.5)) * 0.4
        spike.material_override = mat_spikes
        spike.position = Vector3(side * 0.6, 2.2, (row - 1.5) * 0.9)
        spike.rotation_degrees.x = -25 + (row * 10)
        spike.rotation_degrees.z = side * 20
        mesh_node.add_child(spike)

    # Bioluminescent Cluster Eyes
    for i in range(4):
        var eye = MeshInstance3D.new()
        eye.mesh = SphereMesh.new()
        eye.mesh.radius = 0.15
        eye.material_override = mat_eyes
        var side = -1.0 if (i % 2 == 0) else 1.0
        var row_offset = float(int(i / 2.0))
        eye.position = Vector3(side * (0.3 + row_offset * 0.25), 1.6 + row_offset * 0.2, -1.8)
        mesh_node.add_child(eye)

    # Scuttling Chitin Legs (6 Spider-like Needle Legs)
    for i in range(6):
        var leg = MeshInstance3D.new()
        leg.mesh = CylinderMesh.new()
        leg.mesh.top_radius = 0.12
        leg.mesh.bottom_radius = 0.04
        leg.mesh.height = 2.2
        leg.material_override = mat_chitin
        var side = -1.0 if (i % 2 == 0) else 1.0
        var row = float(int(i / 2.0))
        leg.position = Vector3(side * 1.4, 0.7, (row - 1.0) * 1.1)
        leg.rotation_degrees.z = side * 35.0
        mesh_node.add_child(leg)

func _physics_process(delta):
    super._physics_process(delta)
    # Fast erratic insectoid scuttle
    if Vector2(velocity.x, velocity.z).length() > 0.1 and mesh:
        walk_time += delta * speed * 6.0
        mesh.position.y = abs(sin(walk_time)) * 0.15
        mesh.rotation_degrees.y = sin(walk_time * 0.5) * 5.0
    elif mesh:
        mesh.position.y = 0
        mesh.rotation_degrees.y = 0
