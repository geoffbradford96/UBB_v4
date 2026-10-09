extends "res://Scripts/Unit.gd"

func _ready():
    super._ready()
    # Procedural mesh generation for ScrapMech
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    self.mesh = mesh_node
    

    var mat_rust = StandardMaterial3D.new()
    mat_rust.albedo_color = Color(0.55, 0.28, 0.12)
    mat_rust.metallic = 0.5
    mat_rust.roughness = 0.9

    var mat_iron = StandardMaterial3D.new()
    mat_iron.albedo_color = Color(0.18, 0.18, 0.20)
    mat_iron.metallic = 0.85
    mat_iron.roughness = 0.4

    var mat_hazard = StandardMaterial3D.new()
    mat_hazard.albedo_color = Color(0.75, 0.60, 0.15)
    mat_hazard.roughness = 0.8

    # Welded Boiler Hull
    var body = MeshInstance3D.new()
    body.mesh = CylinderMesh.new()
    body.mesh.top_radius = 1.3
    body.mesh.bottom_radius = 1.3
    body.mesh.height = 2.2
    body.material_override = mat_rust
    body.position.y = 2.6
    body.rotation_degrees.x = 90
    mesh_node.add_child(body)

    # Scavenged Front Hazard Shield Plate
    var plate = MeshInstance3D.new()
    plate.mesh = BoxMesh.new()
    plate.mesh.size = Vector3(1.8, 1.4, 0.2)
    plate.material_override = mat_hazard
    plate.position = Vector3(0, 2.7, -1.25)
    mesh_node.add_child(plate)

    # Angled Smokestack Exhaust
    var stack = MeshInstance3D.new()
    stack.mesh = CylinderMesh.new()
    stack.mesh.top_radius = 0.25
    stack.mesh.bottom_radius = 0.3
    stack.mesh.height = 1.8
    stack.material_override = mat_iron
    stack.position = Vector3(0.9, 3.8, 0.6)
    stack.rotation_degrees.z = -15
    mesh_node.add_child(stack)

    # Left Heavy Scrap Pincer Claw
    var claw_arm = MeshInstance3D.new()
    claw_arm.mesh = BoxMesh.new()
    claw_arm.mesh.size = Vector3(0.4, 0.4, 1.8)
    claw_arm.material_override = mat_iron
    claw_arm.position = Vector3(-1.6, 2.6, -0.6)
    mesh_node.add_child(claw_arm)

    var pincer1 = MeshInstance3D.new()
    pincer1.mesh = BoxMesh.new()
    pincer1.mesh.size = Vector3(0.2, 0.8, 0.8)
    pincer1.material_override = mat_hazard
    pincer1.position = Vector3(-1.6, 2.9, -1.6)
    pincer1.rotation_degrees.z = 25
    mesh_node.add_child(pincer1)

    var pincer2 = MeshInstance3D.new()
    pincer2.mesh = BoxMesh.new()
    pincer2.mesh.size = Vector3(0.2, 0.8, 0.8)
    pincer2.material_override = mat_hazard
    pincer2.position = Vector3(-1.6, 2.3, -1.6)
    pincer2.rotation_degrees.z = -25
    mesh_node.add_child(pincer2)

    # Right Scrap Cannon / Riveted Flak Barrel
    var cannon = MeshInstance3D.new()
    cannon.mesh = CylinderMesh.new()
    cannon.mesh.top_radius = 0.3
    cannon.mesh.bottom_radius = 0.35
    cannon.mesh.height = 2.4
    cannon.material_override = mat_iron
    cannon.rotation_degrees.x = 90
    cannon.position = Vector3(1.6, 2.6, -1.0)
    mesh_node.add_child(cannon)

    # Heavy Welded Girder Legs
    for side in [-1.0, 1.0]:
        var leg = MeshInstance3D.new()
        leg.mesh = BoxMesh.new()
        leg.mesh.size = Vector3(0.5, 2.0, 0.5)
        leg.material_override = mat_rust
        leg.position = Vector3(side * 1.1, 1.1, 0)
        leg.rotation_degrees.z = side * -12.0
        mesh_node.add_child(leg)

        var foot = MeshInstance3D.new()
        foot.mesh = BoxMesh.new()
        foot.mesh.size = Vector3(0.9, 0.3, 1.3)
        foot.material_override = mat_iron
        foot.position = Vector3(side * 1.25, 0.15, -0.1)
        mesh_node.add_child(foot)

func _animate_mesh(delta: float, moving: bool):
    if moving and mesh:
        walk_time += delta * speed * 3.2
        mesh.position.y = base_mesh_pos.y + abs(sin(walk_time)) * 0.4
        mesh.rotation.z = sin(walk_time) * 0.08
    elif mesh:
        mesh.position.y = lerp(mesh.position.y, base_mesh_pos.y, 10.0 * delta)
        mesh.rotation.z = lerp(mesh.rotation.z, 0.0, 10.0 * delta)
