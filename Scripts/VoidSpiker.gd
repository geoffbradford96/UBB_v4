extends "res://Scripts/Unit.gd"

func _ready():
    super._ready()
    # Procedural mesh generation for VoidSpiker
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    self.mesh = mesh_node
    

    var mat_dark = StandardMaterial3D.new(); mat_dark.albedo_color = Color(0.1, 0.0, 0.2)
    var mat_spike = StandardMaterial3D.new(); mat_spike.albedo_color = Color(0.9, 0.1, 0.9); mat_spike.emission_enabled = true; mat_spike.emission = Color(0.8, 0.0, 0.8)
    var body = MeshInstance3D.new(); body.mesh = CapsuleMesh.new(); body.mesh.radius = 1.5; body.mesh.height = 4.0
    body.material_override = mat_dark; body.position.y = 1.5; body.rotation_degrees.x = 90
    mesh_node.add_child(body)
    for i in range(6):
        var spike = MeshInstance3D.new(); spike.mesh = CylinderMesh.new(); spike.mesh.top_radius = 0.0; spike.mesh.bottom_radius = 0.3; spike.mesh.height = 2.0
        spike.material_override = mat_spike
        spike.position = Vector3((i%2 - 0.5)*2.0, 2.5, (i/2 - 1.0)*1.5)
        spike.rotation_degrees.x = -30
        mesh_node.add_child(spike)

func _physics_process(delta):
    super._physics_process(delta)
    # Simple procedural bobbing/walking animation
    if Vector2(velocity.x, velocity.z).length() > 0.1 and mesh:
        walk_time += delta * speed * 3.0
        mesh.position.y = abs(sin(walk_time)) * 0.5
    elif mesh:
        mesh.position.y = 0
