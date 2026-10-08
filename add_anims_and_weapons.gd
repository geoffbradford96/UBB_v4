extends SceneTree

func _init():
	print("--- Fixing Models, Adding Weapons & Animations ---")
	
	var dir = DirAccess.open("res://Scenes/Units/")
	if dir:
		dir.list_dir_begin()
		var fn = dir.get_next()
		while fn != "":
			if fn.ends_with(".tscn"):
				var u_name = fn.replace(".tscn", "")
				apply_dominion_unit(u_name, "res://Scenes/Units/" + fn)
			fn = dir.get_next()
			
	var vdir = DirAccess.open("res://Scenes/Units/VoidSwarm/")
	if vdir:
		vdir.list_dir_begin()
		var fn = vdir.get_next()
		while fn != "":
			if fn.ends_with(".tscn"):
				var u_name = fn.replace(".tscn", "")
				apply_void_unit(u_name, "res://Scenes/Units/VoidSwarm/" + fn)
			fn = vdir.get_next()
			
	print("--- Done ---")
	quit()

func apply_dominion_unit(u: String, path: String):
	var packed = load(path)
	if not packed: return
	var scene = packed.instantiate()
	var mesh = scene.get_node_or_null("MeshInstance3D")
	if not mesh: return
	
	# 1. Fix limb rotations and placements
	var r_arm = mesh.get_node_or_null("RightArm")
	var l_arm = mesh.get_node_or_null("LeftArm")
	var r_leg = mesh.get_node_or_null("RightLeg")
	var l_leg = mesh.get_node_or_null("LeftLeg")
	
	if r_arm: r_arm.rotation_degrees = Vector3(0, 0, 0)
	if l_arm: l_arm.rotation_degrees = Vector3(0, 0, 0)
	if r_leg: r_leg.rotation_degrees = Vector3(0, 0, 0)
	if l_leg: l_leg.rotation_degrees = Vector3(0, 0, 0)
	
	# 2. Add Weapons to Right Arm
	if r_arm:
		# Clean old weapons
		for c in r_arm.get_children():
			if "Weapon" in c.name: c.queue_free()
			
		var w_mat = StandardMaterial3D.new()
		w_mat.albedo_color = Color(0.2, 0.2, 0.2)
		w_mat.metallic = 0.8
		
		if u == "Medic" or u == "RepairMan":
			var pistol = CSGCombiner3D.new()
			pistol.name = "Weapon_Pistol"
			var barrel = CSGBox3D.new()
			barrel.size = Vector3(0.1, 0.1, 0.3)
			barrel.position = Vector3(0, -0.4, -0.2)
			var grip = CSGBox3D.new()
			grip.size = Vector3(0.1, 0.2, 0.1)
			grip.position = Vector3(0, -0.5, -0.05)
			grip.rotation_degrees = Vector3(20, 0, 0)
			pistol.add_child(barrel)
			pistol.add_child(grip)
			pistol.material_override = w_mat
			r_arm.add_child(pistol)
			
		elif u == "Sniper":
			var rifle = CSGBox3D.new()
			rifle.name = "Weapon_Rifle"
			rifle.size = Vector3(0.1, 0.1, 0.8)
			rifle.position = Vector3(0, -0.4, -0.4)
			rifle.material = w_mat
			r_arm.add_child(rifle)
			
		elif u == "Assassin":
			var blade = CSGBox3D.new()
			blade.name = "Weapon_Blade"
			blade.size = Vector3(0.05, 0.4, 0.1)
			blade.position = Vector3(0, -0.6, -0.1)
			blade.rotation_degrees = Vector3(-45, 0, 0)
			blade.material = w_mat
			r_arm.add_child(blade)
			
		elif u == "Grunt":
			var baton = CSGCylinder3D.new()
			baton.name = "Weapon_Baton"
			baton.radius = 0.05
			baton.height = 0.6
			baton.position = Vector3(0, -0.5, -0.2)
			baton.rotation_degrees = Vector3(-30, 0, 0)
			baton.material = w_mat
			r_arm.add_child(baton)

	# 3. Add AnimationPlayer
	add_dominion_animations(scene)
	
	var new_packed = PackedScene.new()
	new_packed.pack(scene)
	ResourceSaver.save(new_packed, path)
	print("Updated Dominion: ", u)

func add_dominion_animations(scene):
	var ap = scene.get_node_or_null("AnimationPlayer")
	if ap: ap.queue_free()
	
	ap = AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	scene.add_child(ap)
	
	var lib = AnimationLibrary.new()
	
	# --- IDLE ---
	var idle = Animation.new()
	idle.length = 2.0
	idle.loop_mode = Animation.LOOP_LINEAR
	var t_idle = idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(t_idle, "MeshInstance3D:position")
	idle.track_insert_key(t_idle, 0.0, Vector3(0, 0.5, 0))
	idle.track_insert_key(t_idle, 1.0, Vector3(0, 0.55, 0))
	idle.track_insert_key(t_idle, 2.0, Vector3(0, 0.5, 0))
	
	var rarm_idle = idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(rarm_idle, "MeshInstance3D/RightArm:rotation")
	idle.track_insert_key(rarm_idle, 0.0, Vector3(deg_to_rad(0), 0, 0))
	
	lib.add_animation("idle", idle)
	
	# --- WALK ---
	var walk = Animation.new()
	walk.length = 1.0
	walk.loop_mode = Animation.LOOP_LINEAR
	var tl = walk.add_track(Animation.TYPE_VALUE)
	walk.track_set_path(tl, "MeshInstance3D/LeftLeg:rotation")
	walk.track_insert_key(tl, 0.0, Vector3(deg_to_rad(30), 0, 0))
	walk.track_insert_key(tl, 0.5, Vector3(deg_to_rad(-30), 0, 0))
	walk.track_insert_key(tl, 1.0, Vector3(deg_to_rad(30), 0, 0))
	
	var tr = walk.add_track(Animation.TYPE_VALUE)
	walk.track_set_path(tr, "MeshInstance3D/RightLeg:rotation")
	walk.track_insert_key(tr, 0.0, Vector3(deg_to_rad(-30), 0, 0))
	walk.track_insert_key(tr, 0.5, Vector3(deg_to_rad(30), 0, 0))
	walk.track_insert_key(tr, 1.0, Vector3(deg_to_rad(-30), 0, 0))
	
	# Arms swing slightly during walk
	var arm_wl = walk.add_track(Animation.TYPE_VALUE)
	walk.track_set_path(arm_wl, "MeshInstance3D/LeftArm:rotation")
	walk.track_insert_key(arm_wl, 0.0, Vector3(deg_to_rad(-20), 0, 0))
	walk.track_insert_key(arm_wl, 0.5, Vector3(deg_to_rad(20), 0, 0))
	walk.track_insert_key(arm_wl, 1.0, Vector3(deg_to_rad(-20), 0, 0))
	
	lib.add_animation("walk", walk)
	
	# --- ATTACK ---
	var attack = Animation.new()
	attack.length = 0.5
	attack.loop_mode = Animation.LOOP_NONE
	var at = attack.add_track(Animation.TYPE_VALUE)
	attack.track_set_path(at, "MeshInstance3D/RightArm:rotation")
	attack.track_insert_key(at, 0.0, Vector3(deg_to_rad(0), 0, 0))
	attack.track_insert_key(at, 0.1, Vector3(deg_to_rad(60), 0, 0)) # lift weapon
	attack.track_insert_key(at, 0.5, Vector3(deg_to_rad(0), 0, 0))
	
	lib.add_animation("attack", attack)
	
	ap.add_animation_library("", lib)

func apply_void_unit(u: String, path: String):
	var packed = load(path)
	if not packed: return
	var scene = packed.instantiate()
	
	# Add AnimationPlayer
	var ap = scene.get_node_or_null("AnimationPlayer")
	if ap: ap.queue_free()
	
	ap = AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	scene.add_child(ap)
	
	var lib = AnimationLibrary.new()
	
	# --- IDLE (Skitter/Digging) ---
	var idle = Animation.new()
	idle.length = 0.4
	idle.loop_mode = Animation.LOOP_LINEAR
	
	# Find legs to twitch
	var mesh = scene.get_node_or_null("MeshInstance3D")
	if mesh:
		for i in range(8):
			var leg = mesh.get_node_or_null("Leg" + str(i))
			if leg:
				var t = idle.add_track(Animation.TYPE_VALUE)
				idle.track_set_path(t, "MeshInstance3D/Leg" + str(i) + ":position")
				var base_pos = leg.position
				idle.track_insert_key(t, 0.0, base_pos)
				idle.track_insert_key(t, 0.2, base_pos + (Vector3(0, 0.1, 0) if i%2==0 else Vector3(0, -0.1, 0)))
				idle.track_insert_key(t, 0.4, base_pos)
				
	lib.add_animation("idle", idle)
	
	# --- WALK (Scurry wave) ---
	var walk = Animation.new()
	walk.length = 0.6
	walk.loop_mode = Animation.LOOP_LINEAR
	if mesh:
		for i in range(8):
			var leg = mesh.get_node_or_null("Leg" + str(i))
			if leg:
				var t = walk.add_track(Animation.TYPE_VALUE)
				walk.track_set_path(t, "MeshInstance3D/Leg" + str(i) + ":rotation")
				var offset = i * 10
				walk.track_insert_key(t, 0.0, leg.rotation + Vector3(0, deg_to_rad(offset), 0))
				walk.track_insert_key(t, 0.3, leg.rotation + Vector3(0, deg_to_rad(-offset), 0))
				walk.track_insert_key(t, 0.6, leg.rotation + Vector3(0, deg_to_rad(offset), 0))
				
	lib.add_animation("walk", walk)
	
	# --- ATTACK (Lunge/Spit) ---
	var attack = Animation.new()
	attack.length = 0.5
	attack.loop_mode = Animation.LOOP_NONE
	var ta = attack.add_track(Animation.TYPE_VALUE)
	attack.track_set_path(ta, "MeshInstance3D:rotation")
	attack.track_insert_key(ta, 0.0, Vector3(0, 0, 0))
	attack.track_insert_key(ta, 0.2, Vector3(deg_to_rad(-30), 0, 0)) # rear back
	attack.track_insert_key(ta, 0.3, Vector3(deg_to_rad(20), 0, 0)) # lunge forward
	attack.track_insert_key(ta, 0.5, Vector3(0, 0, 0))
	
	lib.add_animation("attack", attack)
	
	ap.add_animation_library("", lib)
	
	var new_packed = PackedScene.new()
	new_packed.pack(scene)
	ResourceSaver.save(new_packed, path)
	print("Updated Void Swarm: ", u)

