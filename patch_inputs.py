with open("project.godot", "r") as f:
    text = f.read()

if "[input]" in text and "p5_up" not in text:
    p56_inputs = """
p5_up={
"deadzone": 0.5,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":4,"axis":1,"axis_value":-1.0,"script":null)
]
}
p5_down={
"deadzone": 0.5,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":4,"axis":1,"axis_value":1.0,"script":null)
]
}
p5_left={
"deadzone": 0.5,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":4,"axis":0,"axis_value":-1.0,"script":null)
]
}
p5_right={
"deadzone": 0.5,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":4,"axis":0,"axis_value":1.0,"script":null)
]
}
p5_action={
"deadzone": 0.5,
"events": [Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":4,"button_index":0,"pressure":0.0,"pressed":false,"script":null)
]
}
p6_up={
"deadzone": 0.5,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":5,"axis":1,"axis_value":-1.0,"script":null)
]
}
p6_down={
"deadzone": 0.5,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":5,"axis":1,"axis_value":1.0,"script":null)
]
}
p6_left={
"deadzone": 0.5,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":5,"axis":0,"axis_value":-1.0,"script":null)
]
}
p6_right={
"deadzone": 0.5,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":5,"axis":0,"axis_value":1.0,"script":null)
]
}
p6_action={
"deadzone": 0.5,
"events": [Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":5,"button_index":0,"pressure":0.0,"pressed":false,"script":null)
]
}
p5_prev_card={
"deadzone": 0.5,
"events": [Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":4,"button_index":9,"pressure":0.0,"pressed":false,"script":null)
]
}
p5_next_card={
"deadzone": 0.5,
"events": [Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":4,"button_index":10,"pressure":0.0,"pressed":false,"script":null)
]
}
p6_prev_card={
"deadzone": 0.5,
"events": [Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":5,"button_index":9,"pressure":0.0,"pressed":false,"script":null)
]
}
p6_next_card={
"deadzone": 0.5,
"events": [Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":5,"button_index":10,"pressure":0.0,"pressed":false,"script":null)
]
}"""
    text += p56_inputs
    with open("project.godot", "w") as f:
        f.write(text)
    print("Added p5 and p6 inputs to project.godot")
