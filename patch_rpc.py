with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

old_func = '''func _apply_faction_visuals():
    var teams = ["SideA", "SideB", "SideC", "SideD"]
    for team in teams:
        var faction = _get_team_faction(team)
        for node in get_tree().get_nodes_in_group(team):
            if "Base" in node.name or "Tower" in node.name:
                if "faction" in node: node.faction = faction
                _build_structure_mesh(node, faction, "Tower" in node.name)'''

new_func = '''func _apply_faction_visuals():
    if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        if not multiplayer.is_server():
            return
            
    var teams = ["SideA", "SideB", "SideC", "SideD"]
    for team in teams:
        var faction = _get_team_faction(team)
        if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
            rpc("sync_faction", team, faction)
        else:
            apply_local_faction(team, faction)

@rpc("authority", "call_local", "reliable")
func sync_faction(team: String, faction: String):
    apply_local_faction(team, faction)

func apply_local_faction(team: String, faction: String):
    for node in get_tree().get_nodes_in_group(team):
        if "Base" in node.name or "Tower" in node.name:
            if "faction" in node: node.faction = faction
            _build_structure_mesh(node, faction, "Tower" in node.name)'''

text = text.replace(old_func, new_func)

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)
