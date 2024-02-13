tool
extends Spatial

#This script is used for:
#-making uninteractable objects extend to maxZ (length of the world in z-direction)
#-showing uninteractable objects in editor

export(Mesh) var meshShape setget showMeshInEditor,isalsoneeded
export(Texture) var texture
export(float) var extraZ # Make the object longer in z direction than maxZ. Is used so 2 objects do not overlap

func _ready():
	if Engine.editor_hint:
		# Code to execute in editor.
		add_child(x)
			
	if not Engine.editor_hint:
		# Code to execute in game. 
		#Extend uninteractable object to maxZ
		var _ObjectMesh = get_child(0)
		var meshExtension = _ObjectMesh.createExtension(Vector3(0,0,get_parent().maxZ + extraZ))
		_ObjectMesh.addExtensionToMesh(meshExtension)
		_ObjectMesh.finalizeExtension()
		#make mesh visible in editor invisible in game
		get_child(1).visible = false
	
#To show in editor
var isneeded
var x = MeshInstance.new()
func showMeshInEditor(var newMesh):
	while (get_child_count()>1):
		remove_child(get_child(get_child_count()-1))
	add_child(x)
	x.set_mesh(newMesh)
	var material = SpatialMaterial.new()
	material.set_cull_mode(material.CULL_DISABLED)
	material.albedo_texture = texture;
	x.set_surface_material(0,material)
	isneeded = newMesh

func isalsoneeded():
	return isneeded
