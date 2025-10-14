extends KinematicBody2D
export(int) var speed := 300

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var direction = Input.get_vector("Left", "Right", "Up", "Down")
	var velocity = direction * speed
	move_and_slide(velocity)

