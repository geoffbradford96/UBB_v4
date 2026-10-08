import sys

with open('d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'r') as f:
    lines = f.readlines()
    
out = []
skip = False
for i, line in enumerate(lines):
    if '# Rotate to face target while attacking' in line:
        skip = True
        out.append(line)
        continue
        
    if skip and 'func find_new_target():' in line:
        skip = False
        
        replacement = """\t\t\tvar look_target = Vector3(current_target.global_position.x, global_position.y, current_target.global_position.z)
\t\t\tif global_position.distance_to(look_target) > 0.1:
\t\t\t\tlook_at(look_target, Vector3.UP)
\t\t\t\t
\t\t\tattack_timer -= delta
\t\t\tif attack_timer <= 0:
\t\t\t\tattack_timer = 1.0 / attack_speed
\t\t\t\tvar target_health = current_target.get_node_or_null("HealthComponent")
\t\t\t\tif target_health:
\t\t\t\t\ttarget_health.take_damage(attack_damage)
\t\t\t\t\tvar ap = get_node_or_null("AnimationPlayer")
\t\t\t\t\tif ap and ap.has_animation("attack"):
\t\t\t\t\t\tap.play("attack", -1, attack_speed)
\telse:
\t\tvelocity.x = move_toward(velocity.x, 0, speed)
\t\tvelocity.z = move_toward(velocity.z, 0, speed)

\tmove_and_slide()
\t
\tvar ap = get_node_or_null("AnimationPlayer")
\tif ap:
\t\tif ap.current_animation == "attack" and ap.is_playing():
\t\t\tpass # Let attack finish
\t\telif is_moving:
\t\t\tif ap.has_animation("walk") and ap.current_animation != "walk":
\t\t\t\tap.play("walk", 0.2, speed * 0.5)
\t\telse:
\t\t\tif ap.has_animation("idle") and ap.current_animation != "idle":
\t\t\t\tap.play("idle", 0.2)
\t\t\t\t
"""
        out.append(replacement)
        out.append(line)
        continue
        
    if not skip:
        out.append(line)

with open('d:/Game Dev/UBB_v2/Scripts/Unit.gd', 'w') as f:
    f.write("".join(out))
