with open('d:/Game Dev/UBB_v2/Scripts/Hero.gd', 'r') as f:
    text = f.read()

text = text.replace('var ap = get_node_or_null("AnimationPlayer")\n					if ap and ap.has_animation("attack"):\n						ap.play("attack", -1, attack_speed)', 'var ap2 = get_node_or_null("AnimationPlayer")\n					if ap2 and ap2.has_animation("attack"):\n						ap2.play("attack", -1, attack_speed)')

with open('d:/Game Dev/UBB_v2/Scripts/Hero.gd', 'w') as f:
    f.write(text)
