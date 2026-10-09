extends "res://Scripts/Unit.gd"

func _ready():
    super._ready()
    # Procedural mesh generation for DominionMech
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    self.mesh = mesh_node
    

    var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.3, 0.4, 0.3); mat.metallic = 0.8
    var body = MeshInstance3D.new(); body.mesh = BoxMesh.new(); body.mesh.size = Vector3(2.0, 2.5, 1.5)
    body.material_override = mat; body.position.y = 2.5
    mesh_node.add_child(body)
    var leg1 = MeshInstance3D.new(); leg1.mesh = CylinderMesh.new(); leg1.mesh.top_radius = 0.4; leg1.mesh.bottom_radius = 0.4; leg1.mesh.height = 2.0
    leg1.material_override = mat; leg1.position = Vector3(-0.8, 1.0, 0)
    mesh_node.add_child(leg1)
    var leg2 = MeshInstance3D.new(); leg2.mesh = CylinderMesh.new(); leg2.mesh.top_radius = 0.4; leg2.mesh.bottom_radius = 0.4; leg2.mesh.height = 2.0
    leg2.material_override = mat; leg2.position = Vector3(0.8, 1.0, 0)
    mesh_node.add_child(leg2)
    var gun1 = MeshInstance3D.new(); gun1.mesh = BoxMesh.new(); gun1.mesh.size = Vector3(0.5, 0.5, 2.0)
    gun1.material_override = mat; gun1.position = Vector3(-1.5, 2.5, 1.0)
    mesh_node.add_child(gun1)
    var gun2 = MeshInstance3D.new(); gun2.mesh = BoxMesh.new(); gun2.mesh.size = Vector3(0.5, 0.5, 2.0)
    gun2.material_override = mat; gun2.position = Vector3(1.5, 2.5, 1.0)
    mesh_node.add_child(gun2)

func _physics_process(delta):
    super._physics_process(delta)
    # Simple procedural bobbing/walking animation
    if Vector2(velocity.x, velocity.z).length() > 0.1 and mesh:
        walk_time += delta * speed * 3.0
        mesh.position.y = abs(sin(walk_time)) * 0.5
    elif mesh:
        mesh.position.y = 0
