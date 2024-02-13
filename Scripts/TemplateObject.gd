extends Spatial

#This script is responsible for:
#-storing interactable objects using ObjectMesh.gd
#-starting physics when player requested by player using selection arrow

export(Mesh) var meshShape
export(Texture) var texture
export(PhysicsMaterial) var PM

var _ObjectMesh
var _Rigidbody #rigidbody for physics simulation
var _World

func _ready():
	_ObjectMesh = get_child(0)
	_World = get_parent()
	_Rigidbody = get_child(1)
	_Rigidbody.get_child(0).set_shape(_ObjectMesh.getPhysicsShape())
	_Rigidbody.set_physics_material_override(PM)
	_Rigidbody.gravity_scale = _World.Gravity
	

#forwards position from physics simulation to objectMesh so it can extend the mesh to the new position
func _interfaceWithObjectMesh(toPos):
	var meshExtension = _ObjectMesh.createExtension(toPos)
	_ObjectMesh.addExtensionToMesh(meshExtension)

func _finishObject():
	_ObjectMesh.finalizeExtension()

#prepares and starts mesh change from position where player wants to throw object
func initiateCalc(direction, z):
	#gets the current center of object for this specific z
	var pos = _ObjectMesh.getPosFromZ(z)
	#Delete everything that is bigger (further in the future) than the current z
	_ObjectMesh.deleteExtensionsFromMesh(pos)
	#starts physics simulation from current center
	_Rigidbody.changeLastOrigin(z)
	_Rigidbody.transform.origin = pos
	_Rigidbody.set_mode(0)
	_Rigidbody.apply_central_impulse(Vector3(direction.x, direction.y, 0))
