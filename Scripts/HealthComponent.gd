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
	
	var sprite = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture = hp_viewport.get_texture()
	
	if "Base" in get_parent().name:
		sprite.position = Vector3(0, 6.0, 0)
		hp_viewport.size = Vector2i(400, 40)
	elif "Tower" in get_parent().name:
		sprite.position = Vector3(0, 7.5, 0)
	else:
		sprite.position = Vector3(0, 3.0, 0)
		
	get_parent().call_deferred("add_child", hp_viewport)
	get_parent().call_deferred("add_child", sprite)

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
						am._end_match("MATCH OVER! " + winner + " IS VICTORIOUS!")
					elif winner == my_team:
						am._end_match("VICTORY! All opposing bases destroyed.")
					else:
						am._end_match("DEFEAT! " + winner + " destroyed all opposing bases.")
					return


	# Destruction burst effect
	var parent_pos = get_parent().global_position
	var puff = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 1.0 if not "Base" in get_parent().name else 3.0
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

	get_parent().queue_free()



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
