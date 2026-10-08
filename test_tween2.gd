extends SceneTree
func _init():
    var tween = create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_interval(1.0)
    tween.tween_callback(func(): print("1 second passed!"))
    tween.tween_interval(1.0)
    tween.tween_callback(func(): print("2 seconds passed!"); quit())
    self.paused = true
