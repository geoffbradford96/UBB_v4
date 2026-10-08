with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'r') as f:
    text = f.read()

text = text.replace('update_health_bar()', 'if hp_bar: hp_bar.value = current_health\n\t\t\temit_signal("health_changed", current_health, max_health)')

with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'w') as f:
    f.write(text)
