extends "res://Scripts/Unit.gd"

func _ready():
    super._ready()
    # Procedural mesh generation for RimworlderLeviathan
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    self.mesh = mesh_node
    

    var mat_beast = StandardMaterial3D.new(); mat_beast.albedo_color = Color(0.1, 0.6, 0.2)
    var body = MeshInstance3D.new(); body.mesh = SphereMesh.new(); body.mesh.radius = 2.5; body.mesh.height = 4.0
    body.material_override = mat_beast; body.position.y = 2.5; body.rotation_degrees.x = 90
    mesh_node.add_child(body)
    var head = MeshInstance3D.new(); head.mesh = SphereMesh.new(); head.mesh.radius = 1.5
    head.material_override = mat_beast; head.position = Vector3(0, 3.0, 2.5)
    mesh_node.add_child(head)
    for i in range(4):
        var leg = MeshInstance3D.new(); leg.mesh = CylinderMesh.new(); leg.mesh.top_radius = 0.6; leg.mesh.bottom_radius = 0.6; leg.mesh.height = 3.0
        leg.material_override = mat_beast
        var x = (i%2 - 0.5)*4.0; var z = (i/2 - 0.5)*3.0
        leg.position = Vector3(x, 1.5, z)
        leg.rotation_degrees.z = 20 if x < 0 else -20
        mesh_node.add_child(leg)

func _physics_process(delta):
    super._physics_process(delta)
    # Simple procedural bobbing/walking animation
    if Vector2(velocity.x, velocity.z).length() > 0.1 and mesh:
        walk_time += delta * speed * 3.0
        mesh.position.y = abs(sin(walk_time)) * 0.5
    elif mesh:
        mesh.position.y = 0
