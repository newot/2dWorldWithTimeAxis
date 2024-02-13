extends RigidBody

#This script is responsible for:
#-calculating the physics of interactable objects

#Uses rigidbody for physics simulations and periodically grabs position of said rigidbody
#The rigidbody has a thin version of the interactable objects collision shape and it slides accross the z-axis
#The frequency in which objects are grabed is determined by DistanceBetweenTime in world.gd

var _TemplateObject #The interactable object
var _lastOrigin #the previous transform.origin

func _ready():
	_TemplateObject = get_parent()
	_lastOrigin = 0
	add_collision_exception_with(_TemplateObject.get_child(0).get_child(0))

func _physics_process(_delta):
	#Checks if distance between the last grab and now is big enough
	if(transform.origin.z - _lastOrigin >= _TemplateObject._World.DistanceBetweenTime):
		_TemplateObject._interfaceWithObjectMesh(transform.origin)
		_lastOrigin = transform.origin.z
	#Checks if rigidbody has reached the end (maximum z as determined by world.gd) to grab position
	if(transform.origin.z >= _TemplateObject._World.maxZ):
		_TemplateObject._finishObject()
		#simulation is stoped when rigidbody reaches the end
		set_mode(MODE_STATIC)

#changes last origin to where the rigidbody needs to start the next physics simulation
func changeLastOrigin(posZ):
	_lastOrigin = posZ
		
#slides object accross z-axis
func _integrate_forces(_state):
	if(get_mode() == MODE_RIGID):
		set_linear_velocity(Vector3(get_linear_velocity().x,get_linear_velocity().y,25))
