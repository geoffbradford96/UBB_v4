with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'r') as f:
    text = f.read()

# Make BotAI abort process if it's a client in an online match
process_fix = '''func _process(delta):
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			return # Let the server handle AI thinking in online matches!
'''

text = text.replace('func _process(delta):', process_fix)

with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'w') as f:
    f.write(text)
