with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if line.strip() == 'class_name HealthComponent':
        new_lines.insert(1, line)
    else:
        new_lines.append(line)

with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'w') as f:
    f.writelines(new_lines)
