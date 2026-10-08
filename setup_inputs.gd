extends SceneTree

func _init():
    # Setup inputs for 4 players
    for p in range(1, 5):
        var prefix = "p" + str(p) + "_"
        var device_id = p - 1 # P1 = device 0, P2 = device 1
        
        # We'll create actions like p1_up, p1_down
        for action in ["up", "down", "left", "right", "action"]:
            var action_name = prefix + action
            if not ProjectSettings.has_setting("input/" + action_name):
                var event = InputEventJoypadMotion.new()
                if action == "up": event.axis = JOY_AXIS_LEFT_Y; event.axis_value = -1.0
                if action == "down": event.axis = JOY_AXIS_LEFT_Y; event.axis_value = 1.0
                if action == "left": event.axis = JOY_AXIS_LEFT_X; event.axis_value = -1.0
                if action == "right": event.axis = JOY_AXIS_LEFT_X; event.axis_value = 1.0
                if action == "action": 
                    event = InputEventJoypadButton.new()
                    event.button_index = JOY_BUTTON_A
                
                event.device = device_id
                
                var dict = {
                    "deadzone": 0.5,
                    "events": [event]
                }
                ProjectSettings.set_setting("input/" + action_name, dict)
    
    ProjectSettings.save()
    print("Inputs added to project settings!")
    quit()
