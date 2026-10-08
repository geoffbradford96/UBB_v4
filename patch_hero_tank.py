import re

for script in ['d:/Game Dev/UBB_v2/Scripts/Hero.gd', 'd:/Game Dev/UBB_v2/Scripts/Tank.gd']:
    with open(script, 'r') as f:
        text = f.read()
    
    if 'var is_moving = false' not in text:
        text = text.replace('if current_target != null:', 'var is_moving = false\n\tif current_target != null:')
        
    text = text.replace('velocity = new_velocity\n\t\t\t\telse:', 'velocity = new_velocity\n\t\t\t\tis_moving = true\n\t\t\t\telse:')
    text = text.replace('velocity = new_velocity\n\t\telse:', 'velocity = new_velocity\n\t\t\tis_moving = true\n\t\telse:')
    
    if 'ap.play("attack"' not in text:
        trigger = 'target_health.take_damage(attack_damage)\n\t\t\t\t\tvar ap = get_node_or_null("AnimationPlayer")\n\t\t\t\t\tif ap and ap.has_animation("attack"):\n\t\t\t\t\t\tap.play("attack", -1, attack_speed)'
        text = text.replace('target_health.take_damage(attack_damage)', trigger)

    if 'ap.current_animation' not in text:
        anim_block = '''	move_and_slide()
	
	var ap = get_node_or_null("AnimationPlayer")
	if ap:
		if ap.current_animation == "attack" and ap.is_playing():
			pass
		elif is_moving:
			if ap.has_animation("walk") and ap.current_animation != "walk":
				ap.play("walk", 0.2, speed * 0.5)
		else:
			if ap.has_animation("idle") and ap.current_animation != "idle":
				ap.play("idle", 0.2)'''
				
        text = text.replace('	move_and_slide()', anim_block)

    with open(script, 'w') as f:
        f.write(text)
        
print("Patched Hero and Tank")
