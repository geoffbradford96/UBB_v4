extends CharacterBody3D

@export var damage: float = 40.0
@export var attack_range: float = 12.0
@export var attack_rate: float = 1.0

var current_target: Node3D = null
var attack_timer: float = 0.0

func _ready():
    add_to_group("Targetable")
    add_to_group("Beast")
    
    # Tentacle procedural visual
    var mesh_node = Node3D.new()
    add_child(mesh_node)
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.4, 0.1, 0.5)
    
    var tent = MeshInstance3D.new()
    tent.mesh = CapsuleMesh.new()
    tent.mesh.radius = 1.0
    tent.mesh.height = 10.0
    tent.material_override = mat
    tent.position.y = 5.0
    mesh_node.add_child(tent)
    
    var eye = MeshInstance3D.new()
    eye.mesh = SphereMesh.new()
    eye.mesh.radius = 1.2
    var eye_mat = StandardMaterial3D.new()
    eye_mat.albedo_color = Color(1.0, 0, 0)
    eye_mat.emission_enabled = true
    eye_mat.emission = Color(1.0, 0, 0)
    eye.material_override = eye_mat
    eye.position.y = 9.0
    eye.position.z = 0.8
    mesh_node.add_child(eye)
    
    self.set_meta("mesh_node", mesh_node)

func _physics_process(delta):
    pass
    
    var mn = get_meta("mesh_node")
    if mn and attack_timer < attack_rate - 0.3: # Only sway if not attacking right now
        mn.rotation_degrees.x = sin(Time.get_ticks_msec() * 0.003) * 15.0
        
    if current_target == null or not is_instance_valid(current_target):
        find_new_target()
        
    if current_target != null:
        var dist = global_position.distance_to(current_target.global_position)
        var effective_range = attack_range
        if "Base" in current_target.name: effective_range += 5.5
        elif "Tower" in current_target.name or "CommandBay" in current_target.name: effective_range += 2.5
        
        if dist <= effective_range:
            attack_timer += delta
            if attack_timer >= attack_rate:
                attack_timer = 0.0
                var hp = current_target.get_node_or_null("HealthComponent")
                if hp: hp.take_damage(damage)
                # Slap animation
                if mn:
                    if has_meta("attack_tween"):
                        var old_tw = get_meta("attack_tween")
                        if is_instance_valid(old_tw) and old_tw.is_valid():
                            old_tw.kill()
                    var tw = create_tween()
                    set_meta("attack_tween", tw)
                    tw.tween_property(mn, "rotation_degrees:x", 60.0, 0.1)
                    tw.tween_property(mn, "rotation_degrees:x", 0.0, 0.2)
        else:
            current_target = null

func find_new_target():
    current_target = null
    var enemies = []
    for node in get_tree().get_nodes_in_group("Targetable"):
        if not node.is_in_group("Beast") and is_instance_valid(node) and node != self:
            enemies.append(node)
    
    var closest = 99999.0
    for e in enemies:
        if is_instance_valid(e):
            var d = global_position.distance_to(e.global_position)
            var effective_range = attack_range + 0.5
            if "Base" in e.name: effective_range += 5.5
            elif "Tower" in e.name or "CommandBay" in e.name: effective_range += 2.5
            
            if d < effective_range and d < closest:
                closest = d
                current_target = e
