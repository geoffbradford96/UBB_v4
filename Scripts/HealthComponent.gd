extends Node
class_name HealthComponent

var poison_ticks: int = 0
var poison_dps: float = 0.0
var poison_timer: float = 0.0
var scrap_heal_time: float = 0.0

func apply_poison(ticks: int, dps: float):
	var parent = get_parent()
	if parent and parent.get("unit_attribute") == "Golem":
		return # Immune to poison attrition!
	poison_ticks = ticks
	poison_dps = dps
	poison_timer = 1.0


signal died
signal health_changed(new_health, max_health)

@export var max_health: float = 100.0
var current_health: float
var is_dead: bool = false

var hp_bar: ProgressBar
var hp_viewport: SubViewport = null
var hp_sprite: Sprite3D = null

func _ready():
	get_parent().add_to_group("Targetable")
	current_health = max_health
	
	# Create Health Bar UI dynamically
	hp_viewport = SubViewport.new()
	hp_viewport.transparent_bg = true
	hp_viewport.size = Vector2i(200, 30)
	hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = max_health
	hp_bar.value = current_health
	hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_bar.show_percentage = false
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(1, 0, 0)
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0, 1, 0)
	hp_bar.add_theme_stylebox_override("background", style_bg)
	hp_bar.add_theme_stylebox_override("fill", style_fg)
	
	hp_viewport.add_child(hp_bar)
	
	hp_sprite = Sprite3D.new()
	hp_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_sprite.texture = hp_viewport.get_texture()
	
	if "Base" in get_parent().name:
		hp_sprite.position = Vector3(0, 6.0, 0)
		hp_viewport.size = Vector2i(400, 40)
	elif "Tower" in get_parent().name:
		hp_sprite.position = Vector3(0, 7.5, 0)
	else:
		hp_sprite.position = Vector3(0, 3.0, 0)
		
	get_parent().call_deferred("add_child", hp_viewport)
	get_parent().call_deferred("add_child", hp_sprite)

func _refresh_hp_visuals():
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
	if hp_viewport:
		hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func take_damage(amount: float):
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			return # Only Server handles damage logic
		rpc("sync_take_damage", amount)
	else:
		sync_take_damage(amount)

@rpc("authority", "call_local", "reliable")
func sync_take_damage(amount: float):
	if is_dead: return
	current_health -= amount
	if hp_bar:
		hp_bar.value = current_health
		if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0:
		die()

func heal(amount: float):
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			return
		rpc("sync_heal", amount)
	else:
		sync_heal(amount)

@rpc("authority", "call_local", "reliable")
func sync_heal(amount: float):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	if hp_bar:
		hp_bar.value = current_health
		if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	emit_signal("health_changed", current_health, max_health)
	

func die():
	if is_dead: return
	is_dead = true
	# SCRAP TANK EXPLOSION
	if "ScrapTank" in get_parent().name:
		for e in get_tree().get_nodes_in_group("Targetable"):
			if e != get_parent() and is_instance_valid(e) and get_parent().global_position.distance_to(e.global_position) < 4.0:
				# Don't explode on own team!
				var explode = true
				for g in get_parent().get_groups():
					if g.begins_with("Side") and e.is_in_group(g): explode = false
				if explode:
					var hp = e.get_node_or_null("HealthComponent")
					if hp: hp.take_damage(50.0)

	# SCRAP HEAL TRIGGER
	var my_t = ""
	for g in get_parent().get_groups():
		if g.begins_with("Side"): my_t = g
	if my_t != "":
		for a in get_tree().get_nodes_in_group(my_t):
			if a != get_parent() and is_instance_valid(a) and "Scrap" in a.name and get_parent().global_position.distance_to(a.global_position) < 5.0:
				var hp = a.get_node_or_null("HealthComponent")
				if hp and hp.has_method("trigger_scrap_heal"): hp.trigger_scrap_heal()

	#print(get_parent().name, " was destroyed!")
	emit_signal("died")
	
	if "Base" in get_parent().name:
		var am = get_tree().current_scene
		if am and am.has_method("_end_match"):
			get_parent().remove_from_group("Targetable")
			var my_team = "SideA"
			if am.get("players") and am.players.size() > 0:
				my_team = am.players[0].team
			elif not multiplayer.is_server() and GameState.current_mode.begins_with("ONLINE"):
				my_team = "SideB"
			
			# Collect all remaining teams that have at least one Base alive
			var teams_alive = []
			for b in get_tree().get_nodes_in_group("Targetable"):
				if "Base" in b.name and b != get_parent() and is_instance_valid(b):
					for g in b.get_groups():
						if g.begins_with("Side") and not teams_alive.has(g):
							teams_alive.append(g)

			if GameState.game_mode == "DESTROY_BASE" or am.get("sudden_death_active"):
				if teams_alive.size() == 0:
					am._end_match("DRAW! All bases were destroyed!")
					return
				elif teams_alive.size() == 1:
					var winner = teams_alive[0]
					if GameState.current_mode == "AI_VS_AI":
						am._end_match("MATCH OVER! " + winner + " IS VICTORIOUS!", winner)
					elif winner == my_team:
						am._end_match("VICTORY! All opposing bases destroyed.", winner)
					else:
						am._end_match("DEFEAT! " + winner + " destroyed all opposing bases.", winner)
					return


	# Destruction burst effect
	var parent_node = get_parent()
	var parent_pos = parent_node.global_position
	var puff = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 1.0 if not "Base" in parent_node.name else 3.0
	sm.height = sm.radius * 2.0
	puff.mesh = sm
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.9, 0.45, 0.1, 0.8)
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.emission_enabled = true
	p_mat.emission = Color(1.0, 0.5, 0.1)
	p_mat.emission_energy_multiplier = 2.5
	puff.material_override = p_mat
	get_tree().current_scene.add_child(puff)
	puff.global_position = parent_pos + Vector3(0, 1.0, 0)
	var tw = puff.create_tween()
	tw.tween_property(puff, "scale", Vector3(1.5, 1.5, 1.5), 0.25)
	tw.parallel().tween_property(p_mat, "albedo_color:a", 0.0, 0.25)
	tw.tween_callback(puff.queue_free)

	var is_building = "Base" in parent_node.name or "Tower" in parent_node.name or "CommandBay" in parent_node.name or "ScorpionNest" in parent_node.name or "AntHill" in parent_node.name or parent_node.is_in_group("Structure")
	if is_building:
		_apply_destroyed_building(parent_node)
	else:
		_spawn_unit_corpse(parent_node)
		parent_node.queue_free()

func _apply_destroyed_building(parent: Node3D):
	parent.remove_from_group("Targetable")
	for g in parent.get_groups():
		if g.begins_with("Side") or g == "NeutralStructure":
			parent.remove_from_group(g)
			
	parent.set_physics_process(false)
	parent.set_process(false)
	
	if hp_sprite: hp_sprite.visible = false
	if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	
	var faction_mesh = parent.get_meta("faction_mesh") if parent.has_meta("faction_mesh") else null
	if faction_mesh and is_instance_valid(faction_mesh):
		faction_mesh.queue_free()
		parent.set_meta("faction_mesh", null)
		
	for c in parent.get_children():
		if c is MeshInstance3D or c is CSGShape3D:
			c.queue_free()
			
	var ruined_root = Node3D.new()
	ruined_root.name = "RuinedBuildingVisuals"
	parent.add_child(ruined_root)
	
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.22, 0.20, 0.19)
	r_mat.roughness = 0.95
	
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.12, 0.11, 0.11)
	dark_mat.roughness = 0.98
	
	if "Base" in parent.name:
		var slab = MeshInstance3D.new()
		var sm = BoxMesh.new()
		sm.size = Vector3(10.5, 1.2, 10.5)
		slab.mesh = sm
		slab.material_override = dark_mat
		slab.position.y = 0.6
		ruined_root.add_child(slab)
		
		var heights = [2.8, 3.4, 2.2, 3.8]
		var offsets = [Vector3(-3.5, 0, -3.5), Vector3(3.5, 0, -3.5), Vector3(-3.5, 0, 3.5), Vector3(3.5, 0, 3.5)]
		for i in range(4):
			var wall = MeshInstance3D.new()
			var wm = BoxMesh.new()
			wm.size = Vector3(2.4, heights[i], 2.4)
			wall.mesh = wm
			wall.material_override = r_mat
			wall.position = offsets[i] + Vector3(0, heights[i] * 0.5 + 1.2, 0)
			wall.rotation = Vector3(deg_to_rad(randf_range(-10, 10)), randf() * TAU, deg_to_rad(randf_range(-10, 10)))
			ruined_root.add_child(wall)
			
		var roof = MeshInstance3D.new()
		var rm = BoxMesh.new()
		rm.size = Vector3(6.0, 0.6, 7.0)
		roof.mesh = rm
		roof.material_override = r_mat
		roof.position = Vector3(0.5, 2.2, -0.5)
		roof.rotation = Vector3(deg_to_rad(28.0), deg_to_rad(15.0), deg_to_rad(-18.0))
		ruined_root.add_child(roof)
		
		for i in range(8):
			var r_chunk = MeshInstance3D.new()
			var cm = BoxMesh.new()
			var sz = randf_range(0.8, 1.8)
			cm.size = Vector3(sz, randf_range(0.5, 1.2), sz)
			r_chunk.mesh = cm
			r_chunk.material_override = dark_mat
			var ang = randf() * TAU
			var dist = randf_range(2.0, 6.2)
			r_chunk.position = Vector3(cos(ang) * dist, 0.4, sin(ang) * dist)
			r_chunk.rotation = Vector3(randf() * 0.5, randf() * TAU, randf() * 0.5)
			ruined_root.add_child(r_chunk)
			
	elif "Tower" in parent.name:
		var stump = MeshInstance3D.new()
		var st_m = CylinderMesh.new()
		st_m.top_radius = 1.4
		st_m.bottom_radius = 2.4
		st_m.height = 2.6
		stump.mesh = st_m
		stump.material_override = r_mat
		stump.position.y = 1.3
		ruined_root.add_child(stump)
		
		var spire = MeshInstance3D.new()
		var sp_m = BoxMesh.new()
		sp_m.size = Vector3(0.9, 2.8, 0.9)
		spire.mesh = sp_m
		spire.material_override = dark_mat
		spire.position = Vector3(0.4, 3.2, -0.2)
		spire.rotation = Vector3(deg_to_rad(18.0), deg_to_rad(25.0), deg_to_rad(-14.0))
		ruined_root.add_child(spire)
		
		for i in range(6):
			var rk = MeshInstance3D.new()
			var rk_m = BoxMesh.new()
			var rk_sz = randf_range(0.6, 1.2)
			rk_m.size = Vector3(rk_sz, randf_range(0.4, 0.8), rk_sz)
			rk.mesh = rk_m
			rk.material_override = dark_mat
			var ang = (TAU / 6.0) * i + randf_range(-0.2, 0.2)
			rk.position = Vector3(cos(ang) * 2.8, 0.3, sin(ang) * 2.8)
			rk.rotation = Vector3(randf() * 0.4, randf() * TAU, randf() * 0.4)
			ruined_root.add_child(rk)
			
	elif "CommandBay" in parent.name:
		var pad = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.top_radius = 2.8
		pm.bottom_radius = 3.2
		pm.height = 0.4
		pad.mesh = pm
		pad.material_override = dark_mat
		pad.position.y = 0.2
		ruined_root.add_child(pad)
		
		for i in range(3):
			var strut = MeshInstance3D.new()
			var stm = BoxMesh.new()
			stm.size = Vector3(0.3, 2.2, 0.3)
			strut.mesh = stm
			strut.material_override = r_mat
			var a = (TAU / 3.0) * i
			strut.position = Vector3(cos(a) * 2.2, 0.9, sin(a) * 2.2)
			strut.rotation = Vector3(deg_to_rad(randf_range(20, 45)), a, deg_to_rad(randf_range(-20, 20)))
			ruined_root.add_child(strut)
			
	elif "ScorpionNest" in parent.name:
		var pit_crater = MeshInstance3D.new()
		var pcm = CylinderMesh.new()
		pcm.top_radius = 6.2
		pcm.bottom_radius = 6.8
		pcm.height = 0.08
		pit_crater.mesh = pcm
		pit_crater.material_override = dark_mat
		pit_crater.position.y = 0.04
		ruined_root.add_child(pit_crater)
		
		for i in range(8):
			var sk = MeshInstance3D.new()
			var sm_b = BoxMesh.new()
			sm_b.size = Vector3(randf_range(0.8, 1.5), randf_range(0.4, 0.8), randf_range(0.8, 1.5))
			sk.mesh = sm_b
			sk.material_override = r_mat
			var ang = randf() * TAU
			var d = randf_range(1.5, 5.5)
			sk.position = Vector3(cos(ang) * d, 0.25, sin(ang) * d)
			sk.rotation = Vector3(randf() * 0.4, randf() * TAU, randf() * 0.4)
			ruined_root.add_child(sk)
			
	elif "AntHill" in parent.name:
		var mound = MeshInstance3D.new()
		var mm = CylinderMesh.new()
		mm.top_radius = 1.2
		mm.bottom_radius = 3.6
		mm.height = 0.9
		mound.mesh = mm
		mound.material_override = dark_mat
		mound.position.y = 0.45
		ruined_root.add_child(mound)
		
		var crater = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 1.1
		cm.bottom_radius = 0.4
		cm.height = 0.2
		var crater_mat = StandardMaterial3D.new()
		crater_mat.albedo_color = Color(0.08, 0.06, 0.04)
		crater.mesh = cm
		crater.material_override = crater_mat
		crater.position.y = 0.95
		ruined_root.add_child(crater)

func _spawn_unit_corpse(parent: Node3D):
	var corpse = Node3D.new()
	corpse.name = "Corpse_" + str(parent.name)
	corpse.global_position = parent.global_position
	corpse.global_rotation = parent.global_rotation
	
	var is_mech = parent.get("unit_attribute") == "Mechanical" or "Tank" in parent.name or "Mech" in parent.name or "Plane" in parent.name or "Walker" in parent.name or "Spiker" in parent.name
	var is_beast = parent.get("unit_attribute") == "Beast" or "Scorpion" in parent.name or "Ant" in parent.name or "Squid" in parent.name or "Octopus" in parent.name or "Jellyfish" in parent.name or "Beetle" in parent.name
	
	if is_mech:
		var wreck_mat = StandardMaterial3D.new()
		wreck_mat.albedo_color = Color(0.18, 0.17, 0.16)
		wreck_mat.roughness = 0.95
		wreck_mat.metallic = 0.4
		
		var hull = MeshInstance3D.new()
		var hm = BoxMesh.new()
		var hull_size = Vector3(1.6, 0.7, 2.2) if "Tank" in parent.name else Vector3(1.2, 0.8, 1.2)
		hm.size = hull_size
		hull.mesh = hm
		hull.material_override = wreck_mat
		hull.position.y = hull_size.y * 0.4
		hull.rotation = Vector3(deg_to_rad(randf_range(-12.0, 12.0)), deg_to_rad(randf_range(-15.0, 15.0)), deg_to_rad(randf_range(-15.0, 15.0)))
		corpse.add_child(hull)
		
		var turret = MeshInstance3D.new()
		var tm = BoxMesh.new()
		tm.size = Vector3(0.9, 0.5, 0.9)
		turret.mesh = tm
		turret.material_override = wreck_mat
		turret.position = hull.position + Vector3(0.2, 0.4, -0.1)
		turret.rotation = Vector3(deg_to_rad(25.0), deg_to_rad(45.0), deg_to_rad(15.0))
		corpse.add_child(turret)
		
		var debris = MeshInstance3D.new()
		var dm = CylinderMesh.new()
		dm.top_radius = 0.12
		dm.bottom_radius = 0.15
		dm.height = 1.4
		debris.mesh = dm
		debris.material_override = wreck_mat
		debris.position = hull.position + Vector3(-0.9, 0.1, 0.6)
		debris.rotation = Vector3(deg_to_rad(85.0), deg_to_rad(30.0), deg_to_rad(60.0))
		corpse.add_child(debris)
		
		var scorch = MeshInstance3D.new()
		var sm_cyl = CylinderMesh.new()
		sm_cyl.top_radius = 1.6
		sm_cyl.bottom_radius = 1.7
		sm_cyl.height = 0.02
		var sc_mat = StandardMaterial3D.new()
		sc_mat.albedo_color = Color(0.08, 0.08, 0.08, 0.85)
		sc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		scorch.mesh = sm_cyl
		scorch.material_override = sc_mat
		scorch.position.y = 0.02
		corpse.add_child(scorch)
		
	elif is_beast:
		var beast_mat = StandardMaterial3D.new()
		beast_mat.albedo_color = Color(0.25, 0.22, 0.18)
		beast_mat.roughness = 0.9
		
		var b_scale = 0.4 if "Ant" in parent.name else (0.8 if "Scorpion" in parent.name else 1.2)
		corpse.scale = Vector3(b_scale, b_scale, b_scale)
		
		var carcass = MeshInstance3D.new()
		var cm = SphereMesh.new()
		cm.radius = 0.7
		cm.height = 0.8
		carcass.mesh = cm
		carcass.material_override = beast_mat
		carcass.position.y = 0.25
		carcass.scale = Vector3(1.4, 0.6, 1.8)
		carcass.rotation = Vector3(deg_to_rad(15.0), 0, deg_to_rad(40.0))
		corpse.add_child(carcass)
		
		for i in range(3):
			var frag = MeshInstance3D.new()
			var fm = BoxMesh.new()
			fm.size = Vector3(0.3, 0.1, 0.4)
			frag.mesh = fm
			frag.material_override = beast_mat
			var a = i * 2.1
			frag.position = Vector3(cos(a) * 0.9, 0.05, sin(a) * 0.9)
			frag.rotation = Vector3(randf() * 0.5, randf() * TAU, randf() * 0.5)
			corpse.add_child(frag)
			
	else:
		var body_mat = StandardMaterial3D.new()
		body_mat.albedo_color = Color(0.18, 0.16, 0.15)
		body_mat.roughness = 0.9
		
		var prone_body = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.5, 0.35, 1.3)
		prone_body.mesh = bm
		prone_body.material_override = body_mat
		prone_body.position.y = 0.18
		corpse.add_child(prone_body)
		
		var head = MeshInstance3D.new()
		var hm = SphereMesh.new()
		hm.radius = 0.22
		hm.height = 0.4
		head.mesh = hm
		head.material_override = body_mat
		head.position = Vector3(0, 0.2, -0.75)
		corpse.add_child(head)
		
		var weapon = MeshInstance3D.new()
		var wm = BoxMesh.new()
		wm.size = Vector3(0.08, 0.08, 0.9)
		weapon.mesh = wm
		var w_mat = StandardMaterial3D.new()
		w_mat.albedo_color = Color(0.1, 0.1, 0.1)
		w_mat.metallic = 0.8
		weapon.material_override = w_mat
		weapon.position = Vector3(0.55, 0.06, 0.1)
		weapon.rotation.y = deg_to_rad(28.0)
		corpse.add_child(weapon)

	get_tree().current_scene.add_child(corpse)
	GameState.register_corpse(corpse)



func _process(delta):
	if poison_ticks > 0:
		poison_timer -= delta
		if poison_timer <= 0:
			poison_timer = 1.0
			take_damage(poison_dps)
			poison_ticks -= 1

	if scrap_heal_time > 0:
		scrap_heal_time -= delta
		current_health += 15.0 * delta
		if current_health > max_health: current_health = max_health
		if hp_bar:
			hp_bar.value = current_health
			if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		emit_signal("health_changed", current_health, max_health)
			
	if current_health > 0 and current_health < max_health:
		var parent = get_parent()
		if parent and parent.get("unit_attribute") == "Organic":
			current_health += 1.0 * delta # Slow regen: 1 HP per second
			if current_health > max_health: current_health = max_health
			if hp_bar:
				hp_bar.value = current_health
				if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			emit_signal("health_changed", current_health, max_health)


func trigger_scrap_heal():
	if scrap_heal_time <= 0: print(get_parent().name, " triggers SCRAP HEAL!")
	scrap_heal_time = 2.0

func set_max_health(new_max: float):
	max_health = new_max
	current_health = new_max
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
		if hp_viewport: hp_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
