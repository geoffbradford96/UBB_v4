extends SceneTree
func _init():
    for p in range(1, 5):
        var prefix = "p" + str(p) + "_"
        var device_id = p - 1
        
        var add_btn = func(action, btn):
            var ev = InputEventJoypadButton.new()
            ev.button_index = btn
            ev.device = device_id
            var dict = { "deadzone": 0.5, "events": [ev] }
            ProjectSettings.set_setting("input/" + prefix + action, dict)
            
        add_btn.call("prev_card", JOY_BUTTON_LEFT_SHOULDER)
        add_btn.call("next_card", JOY_BUTTON_RIGHT_SHOULDER)
        
    # Keyboard fallbacks for P1/P2
    var add_key = func(action, key):
        var ev = InputEventKey.new()
        ev.keycode = key
        var dict = ProjectSettings.get_setting("input/" + action)
        dict["events"].append(ev)
        ProjectSettings.set_setting("input/" + action, dict)
        
    add_key.call("p1_prev_card", KEY_Q)
    add_key.call("p1_next_card", KEY_E)
    add_key.call("p2_prev_card", KEY_COMMA)
    add_key.call("p2_next_card", KEY_PERIOD)
    
    ProjectSettings.save()
    print("Shoulder buttons added!")
    quit()
