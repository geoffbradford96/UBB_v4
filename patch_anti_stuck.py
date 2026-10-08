import os

scripts = [
    'd:/Game Dev/UBB_v2/Scripts/Unit.gd',
    'd:/Game Dev/UBB_v2/Scripts/Tank.gd',
    'd:/Game Dev/UBB_v2/Scripts/Hero.gd',
    'd:/Game Dev/UBB_v2/Scripts/Medic.gd',
    'd:/Game Dev/UBB_v2/Scripts/RepairMan.gd',
    'd:/Game Dev/UBB_v2/Scripts/Assassin.gd',
    'd:/Game Dev/UBB_v2/Scripts/HeroHunter.gd',
    'd:/Game Dev/UBB_v2/Scripts/Plane.gd',
    'd:/Game Dev/UBB_v2/Scripts/Sniper.gd',
    'd:/Game Dev/UBB_v2/Scripts/SupportingFire.gd'
]

anti_stuck = '''	# Anti-stuck wall sliding
	if is_on_wall():
		var wall_normal = get_wall_normal()
		var slide_vel = velocity.slide(wall_normal)
		if slide_vel.length() < speed * 0.5:
			var perp = Vector3(wall_normal.z, 0, -wall_normal.x)
			velocity += perp * speed * 1.5
	
	move_and_slide()'''

for script in scripts:
    with open(script, 'r') as f:
        text = f.read()
        
    if '# Anti-stuck wall sliding' not in text:
        text = text.replace('	move_and_slide()', anti_stuck)
        with open(script, 'w') as f:
            f.write(text)

print("Injected Anti-Stuck logic into all units")
