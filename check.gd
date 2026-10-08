extends SceneTree

class Parent extends Node:
    func _process(delta):
        print("Parent process")

class Child extends Parent:
    func _process(delta):
        print("Child process")

func _init():
    var c = Child.new()
    root.add_child(c)
    print("Testing process...")
    await process_frame
    quit()
