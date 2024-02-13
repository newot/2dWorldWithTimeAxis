extends ImmediateGeometry

#This script is responsible for:
#-selecting an object
#-initializing throwing/moving an interactable object
#-drawing an visulisation arrow to aid players wanting to perform those tasks

var camera
var player
var space_state
var object
var ray_length = 1000 #Int: How far a Ray travels in mouse direction to either colide with an object while no object is selected or colide with the z plane while object is selected
var Point1 #Position: center of selected object specifically on current z
var Point2 #Position: intersection of mouse with plane on current z
var object_is_selected #Bool: An object is currently selected
var margin = 0.3 #line thickness

func _ready():
	visible = false
	camera = get_parent().get_child(0).get_child(2).get_child(0).get_child(0)
	player = get_parent().get_child(0)
	space_state = get_world().direct_space_state
	Point1 = Vector3(0,0,0)
	Point2 = Vector3(0,0,0)
	object_is_selected = false
	
func _physics_process(_delta):
	#perform action: Select an object or launch object
	if Input.is_action_just_pressed("select_object"):
		if(object_is_selected):
			#Initiate launch of selected object in the direction the arrow visulisation is pointing
			object.get_parent().get_parent().initiateCalc(Vector2(Point2.x-Point1.x, Point2.y-Point1.y), player.transform.origin.z)
			object_is_selected = false
		else:
			#Find an Object to select
			var from = camera.project_ray_origin(get_viewport().get_mouse_position())
			var to = from + camera.project_ray_normal(get_viewport().get_mouse_position()) * ray_length
			var collision = space_state.intersect_ray(from, to, [], 1)
			if(!collision.empty()):
				if(collision.collider.is_in_group("interactable")):
					object_is_selected = true
					object = collision.collider
	#perform action: Deselect Object
	if Input.is_action_just_pressed("deselect_object"):
		object_is_selected = false
	#Updates arrow visulisation while object is selected
	if(object_is_selected):
		visible = true
		#get the position of Point1 and Point 2. 
		Point1 = object.get_parent().getPosFromZ(player.transform.origin.z) + object.get_parent().get_parent().transform.origin
		var tempPoint2 = getPoint2()
		if(TYPE_VECTOR3 == typeof(tempPoint2)):
			Point2 = tempPoint2
			drawArrow(Point1, Point2)
	else:
		visible = false
	
#Point2 is the intersection of a ray cast in the direction of a mouse with ZPlane, a large thin (on z-axis) collision shape on the same z position as the player
func getPoint2():
	var from = camera.project_ray_origin(get_viewport().get_mouse_position())
	var to = from + camera.project_ray_normal(get_viewport().get_mouse_position()) * ray_length
	var collision = space_state.intersect_ray(from, to, [], 2)
	if(!collision.empty()):
		if(collision.collider.is_in_group("ZPlane")):
			return collision.position
	return false
	
#Draws 3 boxes to create the visulisation arrow
func drawArrow(a,b):
	clear()
	begin(Mesh.PRIMITIVE_TRIANGLES)
	#Figure out position of arrowheads 2 outer points 
	var j = (b-a).normalized()
	var p1 = b-j.rotated(Vector3(0,0,1),0.7853982)*5
	var p2 = b-j.rotated(Vector3(0,0,1),-0.7853982)*5
	
	#Draw all 3 boxes individually
	var verts = triangleVerteciesBox(a,b)
	for i in range(verts.size()):
		add_vertex(verts[i])
	verts = triangleVerteciesBox(p1,b)
	for i in range(verts.size()):
		add_vertex(verts[i])
	verts = triangleVerteciesBox(p2,b)
	for i in range(verts.size()):
		add_vertex(verts[i])
	end()
	
#Vertecies for a box shape using triangles
func triangleVerteciesBox(a,b):
	var verts = []
	var normalized = margin*(a-b).normalized()
	normalized = normalized.rotated(Vector3(0,0,1),1.570796)
	var zAxis = Vector3(0,0,margin)
	
	#++
	verts.append(a-normalized+zAxis)
	verts.append(b+normalized+zAxis)
	verts.append(a+normalized+zAxis)
	
	verts.append(a-normalized+zAxis)
	verts.append(b-normalized+zAxis)
	verts.append(b+normalized+zAxis)
	#+-
	verts.append(a+normalized-zAxis)
	verts.append(a+normalized+zAxis)
	verts.append(b+normalized+zAxis)
	
	verts.append(a+normalized-zAxis)
	verts.append(b+normalized+zAxis)
	verts.append(b+normalized-zAxis)
	#-+
	verts.append(a-normalized-zAxis)
	verts.append(b-normalized+zAxis)
	verts.append(a-normalized+zAxis)
	
	verts.append(a-normalized-zAxis)
	verts.append(b-normalized-zAxis)
	verts.append(b-normalized+zAxis)
	#--
	verts.append(a-normalized-zAxis)
	verts.append(a+normalized-zAxis)
	verts.append(b+normalized-zAxis)
	
	verts.append(a-normalized-zAxis)
	verts.append(b+normalized-zAxis)
	verts.append(b-normalized-zAxis)
	
	#xx
	verts.append(a-normalized-zAxis)
	verts.append(a+normalized+zAxis)
	verts.append(a+normalized-zAxis)
	
	verts.append(a+normalized+zAxis)
	verts.append(a-normalized-zAxis)
	verts.append(a-normalized+zAxis)
	
	#ll
	verts.append(b-normalized-zAxis)
	verts.append(b+normalized-zAxis)
	verts.append(b+normalized+zAxis)
	
	verts.append(b+normalized+zAxis)
	verts.append(b-normalized+zAxis)
	verts.append(b-normalized-zAxis)
	
	return verts
