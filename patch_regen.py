with open('d:/Game Dev/UBB_v2/Scripts/HealthComponent.gd', 'a') as f:
    f.write('''
func _process(delta):
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			return # Only server computes regen
			
	if current_health > 0 and current_health < max_health:
		var parent = get_parent()
		if parent and parent.get("unit_attribute") == "Organic":
			current_health += 1.0 * delta # Slow regen: 1 HP per second
			if current_health > max_health: current_health = max_health
			update_health_bar()
''')
print("Added regen logic to HealthComponent")
