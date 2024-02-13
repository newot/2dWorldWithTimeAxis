extends KinematicBody

#This script is responisble for:
#-character walking
#-character jumping

#Based on: Tutorial on Godot docs

# How fast the player moves in meters per second.
export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
export var fall_acceleration = 2
# Vertical impulse applied to the character upon jumping in meters per second.
export var jump_impulse = 20

var velocity = Vector3.ZERO
var rot_x
var animator

func _ready():
	rot_x = get_child(2).get_child(0).get_child(0)
	animator = get_child(1).get_child(2)
	
func _physics_process(_delta):
	# Movement
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1

	if direction != Vector3.ZERO:
		direction = direction.rotated(Vector3(0, 1, 0), rot_x.GimbalY.rotation.y)
		direction = direction.normalized()
		#print("d:{d},r:{r}".format({"d":direction, "r":rot_x.GimbalY.rotation.y}))
		animator.play("walk")

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y -= fall_acceleration
	velocity = move_and_slide(velocity, Vector3.UP, true)
	
	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y += jump_impulse
