extends SceneTree

func _init():
	var path = "res://Data/Cards/HeavyTankCard.tres"
	var card = load(path)
	if card:
		card.unit_scene = load("res://Scenes/Units/HeavyTank.tscn")
		ResourceSaver.save(card, path)
		print("Updated HeavyTankCard.tres to point to HeavyTank.tscn!")
	quit()
