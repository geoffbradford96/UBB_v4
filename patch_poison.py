with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'r') as f:
    text = f.read()

poison_vars = '''
var poison_ticks: int = 0
var poison_dps: float = 0.0
var poison_timer: float = 0.0

func apply_poison(ticks: int, dps: float):
	var parent = get_parent()
	if parent and parent.get("unit_attribute") == "Golem":
		return # Immune to poison attrition!
	poison_ticks = ticks
	poison_dps = dps
	poison_timer = 1.0
'''

text = text.replace('extends Node', 'extends Node\n' + poison_vars)

process_poison = '''			update_health_bar()
			
	if poison_ticks > 0:
		poison_timer -= delta
		if poison_timer <= 0.0:
			poison_timer = 1.0
			poison_ticks -= 1
			take_damage(poison_dps)
'''

text = text.replace('update_health_bar()', process_poison)

with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'w') as f:
    f.write(text)
