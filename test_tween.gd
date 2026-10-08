extends SceneTree
func _init():
    var tween = create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    print("Success")
    quit()
