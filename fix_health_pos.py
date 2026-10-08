with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'r') as f:
    text = f.read()

text = text.replace('global_position.distance_to', 'get_parent().global_position.distance_to')

with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'w') as f:
    f.write(text)
