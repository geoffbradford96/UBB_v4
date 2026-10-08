import sys

def inject_avoidance(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    out = []
    for line in lines:
        if 'velocity = new_velocity' in line and ('Unit.gd' in filepath or 'Tank.gd' in filepath):
            out.append(line)
            out.append("\t\t\t# --- Separation / Collision Avoidance ---\n")
            out.append("\t\t\tvar my_team = \"\"\n")
            out.append("\t\t\tfor g in get_groups():\n")
            out.append("\t\t\t\tif g.begins_with(\"Side\"): my_team = g\n")
            out.append("\t\t\tvar space_state = get_world_3d().direct_space_state\n")
            out.append("\t\t\tvar query = PhysicsShapeQueryParameters3D.new()\n")
            out.append("\t\t\tvar shape = SphereShape3D.new()\n")
            out.append("\t\t\tshape.radius = 1.2\n")
            out.append("\t\t\tquery.shape = shape\n")
            out.append("\t\t\tquery.transform = global_transform\n")
            out.append("\t\t\tvar results = space_state.intersect_shape(query)\n")
            out.append("\t\t\tvar separation = Vector3.ZERO\n")
            out.append("\t\t\tfor res in results:\n")
            out.append("\t\t\t\tvar col = res.collider\n")
            out.append("\t\t\t\tif col != self and col.is_in_group(my_team):\n")
            out.append("\t\t\t\t\tvar push = global_position - col.global_position\n")
            out.append("\t\t\t\t\tpush.y = 0\n")
            out.append("\t\t\t\t\tvar dist_to_col = push.length()\n")
            out.append("\t\t\t\t\tif dist_to_col < 1.2 and dist_to_col > 0.01:\n")
            out.append("\t\t\t\t\t\tseparation += push.normalized() * (1.2 - dist_to_col)\n")
            out.append("\t\t\tvelocity += separation * speed * 2.0\n")
        else:
            out.append(line)
            
    with open(filepath, 'w') as f:
        f.write("".join(out))

inject_avoidance('d:/Game Dev/UBB_v2/Scripts/Unit.gd')
inject_avoidance('d:/Game Dev/UBB_v2/Scripts/Tank.gd')
print("Avoidance Injected")
