import re

with open("Scripts/ArenaManager.gd", "r") as f:
    text = f.read()

old_mesh_end = """        else:
            var mat_beast = StandardMaterial3D.new(); mat_beast.albedo_color = Color(0.1, 0.6, 0.2); mat_beast.emission_enabled = true; mat_beast.emission = Color(0.0, 0.3, 0.1)
            var core = MeshInstance3D.new()
            core.mesh = SphereMesh.new(); core.mesh.radius = 3.0; core.mesh.height = 4.0
            core.material_override = mat_beast; core.position.y = 2.0
            mesh_node.add_child(core)
            for i in range(5):
                var tent = MeshInstance3D.new()
                tent.mesh = CapsuleMesh.new(); tent.mesh.radius = 0.8; tent.mesh.height = 5.0
                tent.material_override = mat_beast
                tent.position.y = 2.0
                var angle = i * (3.14159 * 2.0 / 5.0)
                tent.position.x = cos(angle) * 2.0; tent.position.z = sin(angle) * 2.0
                tent.rotation_degrees.x = sin(angle) * 45; tent.rotation_degrees.z = -cos(angle) * 45
                mesh_node.add_child(tent)"""

new_mesh_end = """        else:
            var mat_beast = StandardMaterial3D.new(); mat_beast.albedo_color = Color(0.1, 0.6, 0.2); mat_beast.emission_enabled = true; mat_beast.emission = Color(0.0, 0.3, 0.1)
            var core = MeshInstance3D.new()
            core.mesh = SphereMesh.new(); core.mesh.radius = 3.0; core.mesh.height = 4.0
            core.material_override = mat_beast; core.position.y = 2.0
            mesh_node.add_child(core)
            for i in range(5):
                var tent = MeshInstance3D.new()
                tent.mesh = CapsuleMesh.new(); tent.mesh.radius = 0.8; tent.mesh.height = 5.0
                tent.material_override = mat_beast
                tent.position.y = 2.0
                var angle = i * (3.14159 * 2.0 / 5.0)
                tent.position.x = cos(angle) * 2.0; tent.position.z = sin(angle) * 2.0
                tent.rotation_degrees.x = sin(angle) * 45; tent.rotation_degrees.z = -cos(angle) * 45
                mesh_node.add_child(tent)
                
    elif faction == "Pirates":
        if is_tower:
            var body = MeshInstance3D.new()
            body.mesh = BoxMesh.new(); body.mesh.size = Vector3(1.5, 4.0, 1.5)
            var mat_rust = StandardMaterial3D.new(); mat_rust.albedo_color = Color(0.5, 0.2, 0.1); mat_rust.metallic = 0.5
            body.material_override = mat_rust; body.position.y = 2.0
            mesh_node.add_child(body)
            var skull = MeshInstance3D.new()
            skull.mesh = SphereMesh.new(); skull.mesh.radius = 1.0
            var mat_bone = StandardMaterial3D.new(); mat_bone.albedo_color = Color(0.9, 0.9, 0.8)
            skull.material_override = mat_bone; skull.position.y = 4.5
            mesh_node.add_child(skull)
        else:
            var ship = MeshInstance3D.new()
            ship.mesh = BoxMesh.new(); ship.mesh.size = Vector3(7.0, 3.0, 4.0)
            var mat_wood = StandardMaterial3D.new(); mat_wood.albedo_color = Color(0.4, 0.2, 0.1)
            ship.material_override = mat_wood; ship.position.y = 1.5
            mesh_node.add_child(ship)
            var mast = MeshInstance3D.new()
            mast.mesh = CylinderMesh.new(); mast.mesh.radius = 0.2; mast.mesh.height = 5.0
            mast.material_override = mat_wood; mast.position.y = 5.0
            mesh_node.add_child(mast)
            
    elif faction == "The Reach":
        if is_tower:
            var crystal = MeshInstance3D.new()
            crystal.mesh = CylinderMesh.new(); crystal.mesh.top_radius = 0.1; crystal.mesh.bottom_radius = 0.8; crystal.mesh.height = 5.0
            var mat_crys = StandardMaterial3D.new(); mat_crys.albedo_color = Color(0.1, 0.8, 0.9); mat_crys.emission_enabled = true; mat_crys.emission = Color(0.2, 0.9, 1.0)
            crystal.material_override = mat_crys; crystal.position.y = 2.5
            mesh_node.add_child(crystal)
        else:
            var base_crys = MeshInstance3D.new()
            base_crys.mesh = CylinderMesh.new(); base_crys.mesh.top_radius = 2.0; base_crys.mesh.bottom_radius = 4.0; base_crys.mesh.height = 3.0
            var mat_crys = StandardMaterial3D.new(); mat_crys.albedo_color = Color(0.1, 0.8, 0.9); mat_crys.emission_enabled = true; mat_crys.emission = Color(0.1, 0.5, 0.8)
            base_crys.material_override = mat_crys; base_crys.position.y = 1.5
            mesh_node.add_child(base_crys)
            var float_crys = MeshInstance3D.new()
            float_crys.mesh = BoxMesh.new(); float_crys.mesh.size = Vector3(2.0, 4.0, 2.0)
            float_crys.material_override = mat_crys; float_crys.position.y = 6.0
            float_crys.rotation_degrees = Vector3(45, 45, 0)
            mesh_node.add_child(float_crys)"""

text = text.replace(old_mesh_end, new_mesh_end)

with open("Scripts/ArenaManager.gd", "w") as f:
    f.write(text)

print("ArenaManager mesh patched")
