extends SceneTree

func _init():
	print("--- BEGINNING BUG SWEEP ---")
	
	# 1. Sweep Cards
	var cards_dir = "res://Data/Cards/"
	var dir = DirAccess.open(cards_dir)
	var all_cards = []
	if dir:
		dir.list_dir_begin()
		var fn = dir.get_next()
		while fn != "":
			if fn.ends_with(".tres"):
				all_cards.append(cards_dir + fn)
			fn = dir.get_next()
			
	var spell_scenes = []
			
	print("Found ", all_cards.size(), " cards.")
	for c_path in all_cards:
		var card = load(c_path)
		if card == null:
			print("BUG: Card failed to load: ", c_path)
			continue
			
		var unit_path = ""
		if card.unit_scene:
			unit_path = card.unit_scene.resource_path
			
		if unit_path == "":
			print("BUG: Card has no unit_scene assigned: ", c_path)
		elif not ResourceLoader.exists(unit_path):
			print("BUG: Card unit_scene path does not exist: ", unit_path, " in card: ", c_path)
			
		if card.is_spell:
			spell_scenes.append(unit_path)
			
	# 2. Sweep Models (Units)
	var unit_dirs = ["res://Scenes/Units/", "res://Scenes/Units/VoidSwarm/"]
	for ud in unit_dirs:
		var udir = DirAccess.open(ud)
		if udir:
			udir.list_dir_begin()
			var fn = udir.get_next()
			while fn != "":
				if fn.ends_with(".tscn"):
					var scene_path = ud + fn
					var packed = load(scene_path)
					if packed:
						var scene = packed.instantiate()
						
						# Check if it's a spell that accidentally got limbs
						if scene_path in spell_scenes:
							var mesh = scene.get_node_or_null("MeshInstance3D")
							if mesh:
								var has_limbs = false
								for child in mesh.get_children():
									if "Leg" in child.name or "Arm" in child.name:
										has_limbs = true
										child.queue_free()
								if has_limbs:
									print("FIXED BUG: Removed accidental limbs from Spell: ", scene_path)
									var new_packed = PackedScene.new()
									new_packed.pack(scene)
									ResourceSaver.save(new_packed, scene_path)
									
						# Check Health Component
						if not scene_path in spell_scenes:
							var hp = scene.get_node_or_null("HealthComponent")
							if hp == null:
								print("BUG: Unit missing HealthComponent: ", scene_path)
								
					else:
						print("BUG: Failed to load unit scene: ", scene_path)
				fn = udir.get_next()
				
	print("--- SWEEP COMPLETE ---")
	quit()
