extends "res://Scripts/Unit.gd"

func _ready():
    super._ready()
    # Procedural mesh generation for ReachMech
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    self.mesh = mesh_node
    

    var mat_white = StandardMaterial3D.new(); mat_white.albedo_color = Color(0.9, 0.95, 1.0); mat_white.metallic = 0.2
    var mat_glass = StandardMaterial3D.new(); mat_glass.albedo_color = Color(0.1, 0.8, 1.0, 0.6); mat_glass.emission_enabled = true; mat_glass.emission = Color(0.0, 0.5, 1.0)
    var body = MeshInstance3D.new(); body.mesh = SphereMesh.new(); body.mesh.radius = 1.2; body.mesh.height = 1.5
    body.material_override = mat_white; body.position.y = 3.0
    mesh_node.add_child(body)
    var core = MeshInstance3D.new(); core.mesh = SphereMesh.new(); core.mesh.radius = 0.8
    core.material_override = mat_glass; core.position = Vector3(0, 3.0, 0.8)
    mesh_node.add_child(core)
    var wing1 = MeshInstance3D.new(); wing1.mesh = PrismMesh.new(); wing1.mesh.size = Vector3(3.0, 0.2, 1.5)
    wing1.material_override = mat_white; wing1.position = Vector3(-1.5, 3.0, -0.5); wing1.rotation_degrees.z = 15
    mesh_node.add_child(wing1)
    var wing2 = MeshInstance3D.new(); wing2.mesh = PrismMesh.new(); wing2.mesh.size = Vector3(3.0, 0.2, 1.5)
    wing2.material_override = mat_white; wing2.position = Vector3(1.5, 3.0, -0.5); wing2.rotation_degrees.z = -15
    mesh_node.add_child(wing2)

func _physics_process(delta):
    super._physics_process(delta)
    # Simple procedural bobbing/walking animation
    if Vector2(velocity.x, velocity.z).length() > 0.1 and mesh:
        walk_time += delta * speed * 3.0
        mesh.position.y = abs(sin(walk_time)) * 0.5
    elif mesh:
        mesh.position.y = 0

    if mesh:
        mesh.position.y = sin(Time.get_ticks_msec() * 0.002) * 0.5 + 0.5
