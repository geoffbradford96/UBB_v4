extends SceneTree

func _init():
	var vdir = DirAccess.open("res://Scenes/Units/VoidSwarm/")
	if vdir:
		vdir.list_dir_begin()
		var fn = vdir.get_next()
		while fn != "":
			if fn.ends_with(".tscn"):
				var u_name = fn.replace(".tscn", "")
				apply_void_anims(u_name, "res://Scenes/Units/VoidSwarm/" + fn)
			fn = vdir.get_next()
	quit()

func apply_void_anims(u: String, path: String):
	var packed = load(path)
	if not packed: return
	var scene = packed.instantiate()
	
	var ap = scene.get_node_or_null("AnimationPlayer")
	if ap: ap.queue_free()
	
	ap = AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	scene.add_child(ap)
	
	var lib = AnimationLibrary.new()
	var mesh = scene.get_node_or_null("MeshInstance3D")
	
	# --- IDLE (Skitter/Digging) ---
	var idle = Animation.new()
	idle.length = 0.4
	idle.loop_mode = Animation.LOOP_LINEAR
	
	if mesh:
		var legs = ["LeftLeg_0", "RightLeg_0", "LeftLeg_1", "RightLeg_1", "LeftLeg_2", "RightLeg_2", "LeftLeg_3", "RightLeg_3"]
		for i in range(legs.size()):
			var leg_name = legs[i]
			var leg = mesh.get_node_or_null(leg_name)
			if leg:
				var t = idle.add_track(Animation.TYPE_VALUE)
				idle.track_set_path(t, "MeshInstance3D/" + leg_name + ":position")
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
		var legs = ["LeftLeg_0", "RightLeg_0", "LeftLeg_1", "RightLeg_1", "LeftLeg_2", "RightLeg_2", "LeftLeg_3", "RightLeg_3"]
		for i in range(legs.size()):
			var leg_name = legs[i]
			var leg = mesh.get_node_or_null(leg_name)
			if leg:
				var t = walk.add_track(Animation.TYPE_VALUE)
				walk.track_set_path(t, "MeshInstance3D/" + leg_name + ":rotation")
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
	print("Fixed Void Swarm Anims: ", u)
