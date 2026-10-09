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
			var my_team = "SideA" if multiplayer.is_server() or GameState.current_mode == "LOCAL" else "SideB"
			
			if GameState.game_mode == "DESTROY_BASE":
				var my_bases_alive = false
				var enemy_bases_alive = false
				for b in get_tree().get_nodes_in_group("Targetable"):
					if "Base" in b.name and b != get_parent():
						if b.is_in_group(my_team):
							my_bases_alive = true
						else:
							enemy_bases_alive = true
							
				if not my_bases_alive:
					if GameState.current_mode == "AI_VS_AI":
						am._end_match("MATCH OVER! SideB DESTROYED ALL BASES!")
					else:
						am._end_match("DEFEAT! All your team's bases were destroyed.")
					return
				elif not enemy_bases_alive:
					if GameState.current_mode == "AI_VS_AI":
						am._end_match("MATCH OVER! SideA DESTROYED ALL BASES!")
					else:
						am._end_match("VICTORY! All enemy bases destroyed.")
					return
			else:
				# Check for Sudden Death Last One Standing (applies to KOTH too!)
				if am.get("sudden_death_active"):
					var teams_alive = []
					for b in get_tree().get_nodes_in_group("Targetable"):
						if "Base" in b.name and b != get_parent():
							for g in b.get_groups():
								if g.begins_with("Side") and not teams_alive.has(g):
									teams_alive.append(g)
					if teams_alive.size() == 1:
						am._end_match(teams_alive[0] + " WINS SUDDEN DEATH!")
					elif teams_alive.size() == 0:
						am._end_match("NO ONE SURVIVED SUDDEN DEATH!")


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
