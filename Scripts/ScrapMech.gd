extends "res://Scripts/Unit.gd"

func _ready():
    super._ready()
    # Procedural mesh generation for ScrapMech
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    self.mesh = mesh_node
    

    var mat_rust = StandardMaterial3D.new(); mat_rust.albedo_color = Color(0.6, 0.3, 0.1); mat_rust.roughness = 0.9
    var body = MeshInstance3D.new(); body.mesh = CylinderMesh.new(); body.mesh.radius = 1.2; body.mesh.height = 2.0
    body.material_override = mat_rust; body.position.y = 2.5; body.rotation_degrees.x = 90
    mesh_node.add_child(body)
    var leg1 = MeshInstance3D.new(); leg1.mesh = BoxMesh.new(); leg1.mesh.size = Vector3(0.4, 2.5, 0.4)
    leg1.material_override = mat_rust; leg1.position = Vector3(-1.0, 1.25, 0); leg1.rotation_degrees.z = -15
    mesh_node.add_child(leg1)
    var leg2 = MeshInstance3D.new(); leg2.mesh = BoxMesh.new(); leg2.mesh.size = Vector3(0.4, 2.5, 0.4)
    leg2.material_override = mat_rust; leg2.position = Vector3(1.0, 1.25, 0); leg2.rotation_degrees.z = 15
    mesh_node.add_child(leg2)
    var claw = MeshInstance3D.new(); claw.mesh = BoxMesh.new(); claw.mesh.size = Vector3(1.8, 0.3, 1.5)
    claw.material_override = mat_rust; claw.position = Vector3(0, 2.5, 1.5)
    mesh_node.add_child(claw)

func _physics_process(delta):
    super._physics_process(delta)
    # Simple procedural bobbing/walking animation
    if Vector2(velocity.x, velocity.z).length() > 0.1 and mesh:
        walk_time += delta * speed * 3.0
        mesh.position.y = abs(sin(walk_time)) * 0.5
    elif mesh:
        mesh.position.y = 0
