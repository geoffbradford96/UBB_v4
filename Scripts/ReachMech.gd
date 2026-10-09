extends "res://Scripts/Unit.gd"

func _ready():
    super._ready()
    # Procedural mesh generation for ReachMech
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    self.mesh = mesh_node
    

    var mat_white = StandardMaterial3D.new()
    mat_white.albedo_color = Color(0.95, 0.97, 1.0)
    mat_white.roughness = 0.15
    mat_white.metallic = 0.15

    var mat_chrome = StandardMaterial3D.new()
    mat_chrome.albedo_color = Color(0.85, 0.88, 0.95)
    mat_chrome.metallic = 0.9
    mat_chrome.roughness = 0.2

    var mat_cyan = StandardMaterial3D.new()
    mat_cyan.albedo_color = Color(0.0, 0.88, 1.0)
    mat_cyan.emission_enabled = true
    mat_cyan.emission = Color(0.0, 0.88, 1.0)
    mat_cyan.emission_energy_multiplier = 3.5

    # Sleek Porcelain Torso Core
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 1.3
    body.mesh.height = 2.2
    body.material_override = mat_white
    body.position.y = 2.8
    mesh_node.add_child(body)

    # Radiant Cyan Energy Core
    var core = MeshInstance3D.new()
    core.mesh = SphereMesh.new()
    core.mesh.radius = 0.7
    core.material_override = mat_cyan
    core.position = Vector3(0, 2.8, -0.7)
    mesh_node.add_child(core)

    # Levitating Anti-Gravity Drive Ring
    var ring = MeshInstance3D.new()
    ring.mesh = TorusMesh.new()
    ring.mesh.outer_radius = 1.8
    ring.mesh.inner_radius = 1.55
    ring.material_override = mat_cyan
    ring.position.y = 2.2
    mesh_node.add_child(ring)

    # Swept Porcelain Wing Fins
    for side in [-1.0, 1.0]:
        var wing = MeshInstance3D.new()
        wing.mesh = PrismMesh.new()
        wing.mesh.size = Vector3(2.8, 0.25, 1.4)
        wing.material_override = mat_white
        wing.position = Vector3(side * 2.0, 3.2, 0.2)
        wing.rotation_degrees.z = side * -20.0
        wing.rotation_degrees.y = side * 15.0
        mesh_node.add_child(wing)

        var wing_tip = MeshInstance3D.new()
        wing_tip.mesh = SphereMesh.new()
        wing_tip.mesh.radius = 0.2
        wing_tip.material_override = mat_cyan
        wing_tip.position = Vector3(side * 3.4, 3.7, 0.2)
        mesh_node.add_child(wing_tip)

    # Levitating Stabilizer Spire
    var pylon = MeshInstance3D.new()
    pylon.mesh = CylinderMesh.new()
    pylon.mesh.top_radius = 0.1
    pylon.mesh.bottom_radius = 0.4
    pylon.mesh.height = 1.6
    pylon.material_override = mat_chrome
    pylon.position.y = 1.3
    mesh_node.add_child(pylon)

func _physics_process(delta):
    super._physics_process(delta)
    # Anti-gravity hover pulsation and banking
    if mesh:
        var hover = sin(Time.get_ticks_msec() * 0.003) * 0.35 + 0.35
        mesh.position.y = hover
        if Vector2(velocity.x, velocity.z).length() > 0.1:
            mesh.rotation_degrees.z = lerp(mesh.rotation_degrees.z, -velocity.x * 2.5, delta * 5.0)
        else:
            mesh.rotation_degrees.z = lerp(mesh.rotation_degrees.z, 0.0, delta * 5.0)
