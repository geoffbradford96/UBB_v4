extends SceneTree

func _init():
    # Helper to add key
    var add_key = func(action_name, keycode):
        var events = ProjectSettings.get_setting("input/" + action_name)["events"]
        var ev = InputEventKey.new()
        ev.keycode = keycode
        events.append(ev)
        var dict = { "deadzone": 0.5, "events": events }
        ProjectSettings.set_setting("input/" + action_name, dict)

    # P1 WASD
    add_key.call("p1_up", KEY_W)
    add_key.call("p1_down", KEY_S)
    add_key.call("p1_left", KEY_A)
    add_key.call("p1_right", KEY_D)
    add_key.call("p1_action", KEY_SPACE)
    
    # P2 Arrows
    add_key.call("p2_up", KEY_UP)
    add_key.call("p2_down", KEY_DOWN)
    add_key.call("p2_left", KEY_LEFT)
    add_key.call("p2_right", KEY_RIGHT)
    add_key.call("p2_action", KEY_ENTER)

    ProjectSettings.save()
    print("Keyboard fallbacks added!")
    quit()
