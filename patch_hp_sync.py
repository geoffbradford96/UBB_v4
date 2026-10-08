import re

with open("Scripts/HealthComponent.gd", "r") as f:
    text = f.read()

# Remove the gatekeeper in _process
bad_gatekeeper = """func _process(delta):
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not multiplayer.is_server():
			return # Only server computes regen
			
	if poison_ticks > 0:"""

good_gatekeeper = """func _process(delta):
	if poison_ticks > 0:"""

if bad_gatekeeper in text:
    text = text.replace(bad_gatekeeper, good_gatekeeper)
    with open("Scripts/HealthComponent.gd", "w") as f:
        f.write(text)
    print("Fixed _process gatekeeper")
else:
    print("Gatekeeper not found?")
