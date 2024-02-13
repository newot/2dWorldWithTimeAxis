extends Camera

#This script is responsible for:
#-camera rotation
#-camera zoom

#This script is based on: https://kidscancode.org/godot_recipes/4.x/3d/camera_gimbal/index.html

var GimbalY
var GimbalX
export(float) var LookaroundSpeed = 2
export(float) var ZoomSpeed = 1
export(float) var MinZoom = 0.5
export(float) var MaxZoom = 4

export var ray_length = 1000

var space_state

var rot_x = 0
var rot_y = 0
var rot_z = 0
var zoom = MinZoom

func _ready():
	GimbalX = get_parent_spatial()
	GimbalY = get_parent().get_parent_spatial()
	space_state = get_world().direct_space_state
	zoom = MinZoom

func _input(event):
	if event is InputEventMouseMotion and Input.is_action_pressed("move_camera"):
		rot_x = event.relative.x * LookaroundSpeed *0.01
		rot_y = event.relative.y * LookaroundSpeed *0.01
		
		transform.basis = Basis()
		GimbalY.rotate(Vector3(0, 1, 0), rot_x)
		GimbalX.rotate(Vector3(1, 0, 0), rot_y)
		GimbalX.rotation.x = clamp(GimbalX.rotation.x, deg2rad(-60) ,deg2rad(30))

func _unhandled_input(event):
	if event.is_action_pressed("zoom_in"):
		zoom += 0.1
		zoom = clamp(zoom, MinZoom, MaxZoom)
		
	if event.is_action_pressed("zoom_out"):
		zoom -= 0.1
		zoom = clamp(zoom, MinZoom, MaxZoom)
	
func _process(_delta):
	GimbalX.scale = lerp(GimbalX.scale, Vector3(1,1,1) * zoom, ZoomSpeed)

