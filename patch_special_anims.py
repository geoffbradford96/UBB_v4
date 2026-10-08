import re

for script, action, target_method in [('d:/Game Dev/UBB_v2/Scripts/Medic.gd', 'heal', 'target_health.heal(heal_amount)'), ('d:/Game Dev/UBB_v2/Scripts/RepairMan.gd', 'repair', 'target_health.heal(repair_amount)')]:
    with open(script, 'r') as f:
        text = f.read()
    
    # 1. Add is_moving tracking
    if 'var is_moving = false' not in text:
        text = text.replace('if current_target != null:', 'var is_moving = false\n\tif current_target != null:')
        
    text = text.replace('velocity = new_velocity\n\t\telse:', 'velocity = new_velocity\n\t\t\tis_moving = true\n\t\telse:')
    
    # 2. Trigger the action animation
    if 'ap.play("' + action + '")' not in text:
        trigger = target_method + '\n\t\t\t\t\t\tvar ap = get_node_or_null("AnimationPlayer")\n\t\t\t\t\t\tif ap and ap.has_animation("' + action + '"):\n\t\t\t\t\t\t\tap.play("' + action + '")'
        text = text.replace(target_method, trigger)
        
    # 3. Add the AnimationPlayer state machine at the end of _physics_process
    anim_block = '''	move_and_slide()
	
	var ap = get_node_or_null("AnimationPlayer")
	if ap:
		if ap.current_animation == "''' + action + '''" and ap.is_playing():
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
        
print("Patched Medic and RepairMan")
