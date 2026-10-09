extends "res://Scripts/Unit.gd"

func _ready():
    super._ready()
    # Procedural mesh generation for DominionMech
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    self.mesh = mesh_node
    

    var mat_armor = StandardMaterial3D.new()
    mat_armor.albedo_color = Color(0.24, 0.34, 0.18)
    mat_armor.roughness = 0.55
    mat_armor.metallic = 0.35

    var mat_metal = StandardMaterial3D.new()
    mat_metal.albedo_color = Color(0.16, 0.18, 0.20)
    mat_metal.metallic = 0.85
    mat_metal.roughness = 0.35

    var mat_amber = StandardMaterial3D.new()
    mat_amber.albedo_color = Color(1.0, 0.65, 0.1)
    mat_amber.emission_enabled = true
    mat_amber.emission = Color(1.0, 0.65, 0.1)
    mat_amber.emission_energy_multiplier = 2.0

    # Armored Chassis & Torso
    var body = MeshInstance3D.new()
    body.mesh = BoxMesh.new()
    body.mesh.size = Vector3(2.2, 2.2, 2.0)
    body.material_override = mat_armor
    body.position.y = 2.6
    mesh_node.add_child(body)

    # Armored Cockpit Slit / Amber Optics
    var visor = MeshInstance3D.new()
    visor.mesh = BoxMesh.new()
    visor.mesh.size = Vector3(1.4, 0.35, 0.1)
    visor.material_override = mat_amber
    visor.position = Vector3(0, 2.8, -1.05)
    mesh_node.add_child(visor)

    # Heavy Shoulder Armor Pods
    for side in [-1.0, 1.0]:
        var shoulder = MeshInstance3D.new()
        shoulder.mesh = BoxMesh.new()
        shoulder.mesh.size = Vector3(0.8, 1.0, 1.6)
        shoulder.material_override = mat_armor
        shoulder.position = Vector3(side * 1.5, 3.1, 0)
        mesh_node.add_child(shoulder)

        var cannon = MeshInstance3D.new()
        cannon.mesh = CylinderMesh.new()
        cannon.mesh.top_radius = 0.2
        cannon.mesh.bottom_radius = 0.25
        cannon.mesh.height = 2.4
        cannon.material_override = mat_metal
        cannon.rotation_degrees.x = 90
        cannon.position = Vector3(side * 1.5, 3.1, -1.2)
        mesh_node.add_child(cannon)

    # Hydraulic Walker Legs
    for side in [-1.0, 1.0]:
        var hip = MeshInstance3D.new()
        hip.mesh = SphereMesh.new()
        hip.mesh.radius = 0.4
        hip.mesh.height = 0.8
        hip.material_override = mat_metal
        hip.position = Vector3(side * 0.9, 1.6, 0)
        mesh_node.add_child(hip)

        var leg = MeshInstance3D.new()
        leg.mesh = CylinderMesh.new()
        leg.mesh.top_radius = 0.3
        leg.mesh.bottom_radius = 0.35
        leg.mesh.height = 1.6
        leg.material_override = mat_metal
        leg.position = Vector3(side * 0.9, 0.8, 0)
        mesh_node.add_child(leg)

        var foot = MeshInstance3D.new()
        foot.mesh = BoxMesh.new()
        foot.mesh.size = Vector3(0.8, 0.3, 1.2)
        foot.material_override = mat_armor
        foot.position = Vector3(side * 0.9, 0.15, -0.2)
        mesh_node.add_child(foot)

func _animate_mesh(delta: float, moving: bool):
    if moving and mesh:
        walk_time += delta * speed * 3.5
        mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * 0.35
        mesh.rotation.z = sin(walk_time) * 0.05
    elif mesh:
        mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y, 10.0 * delta)
        mesh.rotation.z = lerp(mesh.rotation.z, 0.0, 10.0 * delta)
