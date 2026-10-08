extends "res://Scripts/Unit.gd"

var mine_timer: float = 0.0
var is_placing_mine: bool = false
var place_timer: float = 0.0
var mine_scene = preload("res://Scenes/LandMine.tscn")

func _physics_process(delta):
	# Handle dropping mine
	if is_placing_mine:
		velocity = Vector3.ZERO
		place_timer -= delta
		if place_timer <= 0:
			is_placing_mine = false
			if mine_scene:
				var mine = mine_scene.instantiate()
				get_tree().current_scene.add_child(mine)
				mine.global_position = global_position
				
				var friendly_group = ""
				for g in get_groups():
					if g.begins_with("Side"): friendly_group = g
				mine.add_to_group(friendly_group)
		move_and_slide()
		return
		
	mine_timer += delta
	if mine_timer >= 5.0:
		mine_timer = 0.0
		is_placing_mine = true
		place_timer = 1.0
		return
		
	super._physics_process(delta)
