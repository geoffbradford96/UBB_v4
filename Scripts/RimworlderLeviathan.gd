extends "res://Scripts/Unit.gd"

func _ready():
    super._ready()
    # Procedural mesh generation for RimworlderLeviathan
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    self.mesh = mesh_node
    

    var mat_hide = StandardMaterial3D.new()
    mat_hide.albedo_color = Color(0.38, 0.28, 0.18)
    mat_hide.roughness = 0.9

    var mat_scales = StandardMaterial3D.new()
    mat_scales.albedo_color = Color(0.25, 0.32, 0.18)
    mat_scales.roughness = 0.85

    var mat_bone = StandardMaterial3D.new()
    mat_bone.albedo_color = Color(0.88, 0.84, 0.72)
    mat_bone.roughness = 0.6

    var mat_eyes = StandardMaterial3D.new()
    mat_eyes.albedo_color = Color(1.0, 0.6, 0.1)
    mat_eyes.emission_enabled = true
    mat_eyes.emission = Color(1.0, 0.6, 0.1)
    mat_eyes.emission_energy_multiplier = 2.0

    # Massive Beast Torso
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 2.5
    body.mesh.height = 4.8
    body.material_override = mat_hide
    body.position.y = 2.8
    body.rotation_degrees.x = 90
    mesh_node.add_child(body)

    # Dorsal Mossy Bone Ridge Plates
    for i in range(4):
        var spine = MeshInstance3D.new()
        spine.mesh = PrismMesh.new()
        spine.mesh.size = Vector3(0.6, 1.4 - i*0.2, 1.0)
        spine.material_override = mat_scales
        spine.position = Vector3(0, 4.4 - i*0.2, (i - 1.5) * 1.0)
        mesh_node.add_child(spine)

    # Colossal Horned Head
    var head = MeshInstance3D.new()
    head.mesh = SphereMesh.new()
    head.mesh.radius = 1.6
    head.mesh.height = 2.4
    head.material_override = mat_hide
    head.position = Vector3(0, 3.2, -2.6)
    mesh_node.add_child(head)

    # Feral Glowing Amber Eyes
    for side in [-1.0, 1.0]:
        var eye = MeshInstance3D.new()
        eye.mesh = SphereMesh.new()
        eye.mesh.radius = 0.25
        eye.material_override = mat_eyes
        eye.position = Vector3(side * 0.9, 3.6, -3.2)
        mesh_node.add_child(eye)

    # Giant Curved Ivory Tusks
    for side in [-1.0, 1.0]:
        var tusk = MeshInstance3D.new()
        tusk.mesh = CylinderMesh.new()
        tusk.mesh.top_radius = 0.05
        tusk.mesh.bottom_radius = 0.35
        tusk.mesh.height = 2.6
        tusk.material_override = mat_bone
        tusk.position = Vector3(side * 1.3, 2.8, -3.6)
        tusk.rotation_degrees.x = 55
        tusk.rotation_degrees.y = side * -20
        mesh_node.add_child(tusk)

    # Pillar Quadruped Legs
    for i in range(4):
        var leg = MeshInstance3D.new()
        leg.mesh = CylinderMesh.new()
        leg.mesh.top_radius = 0.7
        leg.mesh.bottom_radius = 0.8
        leg.mesh.height = 2.6
        leg.material_override = mat_hide
        var x = (i % 2 - 0.5) * 3.6
        var z = (i / 2 - 0.5) * 3.0
        leg.position = Vector3(x, 1.3, z)
        leg.rotation_degrees.z = 12 if x < 0 else -12
        mesh_node.add_child(leg)

func _physics_process(delta):
    super._physics_process(delta)
    # Heavy primal lumbering locomotion
    if Vector2(velocity.x, velocity.z).length() > 0.1 and mesh:
        walk_time += delta * speed * 2.8
        mesh.position.y = abs(sin(walk_time)) * 0.35
        mesh.rotation_degrees.z = sin(walk_time) * 2.5
    elif mesh:
        mesh.position.y = 0
        mesh.rotation_degrees.z = 0
