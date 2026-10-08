extends SceneTree

func _init():
	var p = load("res://Scenes/CardUI.tscn")
	if p:
		var scene = p.instantiate()
		var art = scene.get_node_or_null("CardArt")
		if not art:
			art = TextureRect.new()
			art.name = "CardArt"
			# Put it above background but below text
			scene.add_child(art)
			scene.move_child(art, 1) # index 1, just after Background
			
			# Layout
			art.layout_mode = 1 # anchors
			art.anchor_right = 1.0
			art.anchor_bottom = 0.5
			art.offset_left = 10
			art.offset_top = 25
			art.offset_right = -10
			art.offset_bottom = 0
			
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# Ensure owner is set
			art.owner = scene
			
			var pack = PackedScene.new()
			pack.pack(scene)
			ResourceSaver.save(pack, "res://Scenes/CardUI.tscn")
			print("Added CardArt TextureRect to CardUI.tscn!")
	quit()
