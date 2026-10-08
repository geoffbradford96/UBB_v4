extends SceneTree

class Parent extends Node:
    func _ready():
        print("Parent ready")

class Child extends Parent:
    func _ready():
        print("Child ready")

func _init():
    var c = Child.new()
    root.add_child(c)
    print("Testing ready...")
    quit()
