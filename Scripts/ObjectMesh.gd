extends MeshInstance

var meshShape
var texture
var _collisionShape

var _vertsBase #Outline of original shape the extruded version is based upon. points Sorted. NOT A MESH
var _objectVerts = [] #verts for Object mesh
var _objectUVs = [] #Uvs for Object mesh
var _uvcoords = PoolVector2Array()  #Uvcoords for Object mesh
var _vertsCap #Face/Mesh facing z axis imported from model
var _uvsCap #uvs for _vertsCap

func _ready():
	mesh = ArrayMesh.new()
	meshShape = get_parent().meshShape
	texture = get_parent().texture
	
	#MeshdataTool is used to get some information about importet model
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(meshShape,0)
	#get mesh facing z-axis
	_getCapMesh(mdt)
	#get outline
	_vertsBase = _sortBaseMeshWithOutline(_vertsCap, _getOutline(_vertsCap))
	#get Uv Coordinates for outline
	_getUvCoords(mdt, _vertsBase)
	#position from where next extrusion begins
	_lastToPos = Vector3(0,0,0)
	_collisionShape = get_child(0).get_child(0)

#Creates an extrusion from the previous vert position to the in toPos given one
var _lastToPos #last center of object for specific z
func createExtension(toPos):
	var verts = []
	for i in range(_vertsBase.size()-1):
		verts.append(_vertsBase[i] + toPos)
		verts.append(_vertsBase[i+1] + _lastToPos)
		verts.append(_vertsBase[i+1] + toPos)
		
		verts.append(_vertsBase[i] + toPos)
		verts.append(_vertsBase[i] + _lastToPos)
		verts.append(_vertsBase[i+1] + _lastToPos)
		
	verts.append(_vertsBase[_vertsBase.size()-1] + toPos)
	verts.append(_vertsBase[0] + _lastToPos)
	verts.append(_vertsBase[0] + toPos)

	verts.append(_vertsBase[_vertsBase.size()-1] + toPos)
	verts.append(_vertsBase[_vertsBase.size()-1] + _lastToPos)
	verts.append(_vertsBase[0] + _lastToPos)
	
	_lastToPos = toPos
	
	return verts

#Adds an with createExtension created extrusion to the Objects Mesh
func addExtensionToMesh(verts):
	_objectVerts.append_array(verts)
	_objectUVs.append_array(_uvcoords)
	finalizeExtension()
	
#Makes current object mesh visible and functional with caps (faces facing z axis) on both sides, texture and collision
func finalizeExtension():
	#final assembly of model
	var objectVertsWithCap = PoolVector3Array()
	var objectUvsWithCap = PoolVector2Array()
	objectVertsWithCap.append_array(_objectVerts)
	objectUvsWithCap.append_array(_objectUVs)
	#Add everything again with inverted normals
	var vertsCapInvertedNormals = []
	var UvsCapInvertedNormals = []
	for i in range(_vertsCap.size()/3):
		vertsCapInvertedNormals.append(_vertsCap[3*i])
		vertsCapInvertedNormals.append(_vertsCap[3*i+2])
		vertsCapInvertedNormals.append(_vertsCap[3*i+1])
		UvsCapInvertedNormals.append(_uvsCap[3*i])
		UvsCapInvertedNormals.append(_uvsCap[3*i+2])
		UvsCapInvertedNormals.append(_uvsCap[3*i+1])
	objectVertsWithCap.append_array(vertsCapInvertedNormals)
	objectUvsWithCap.append_array(UvsCapInvertedNormals)
	objectUvsWithCap.append_array(_uvsCap)
	
	#Add caps (faces facing z axis) to the mesh
	var pos = (_objectVerts[_objectVerts.size()-3]-_vertsBase[_vertsBase.size()-1])
	for i in range(_vertsCap.size()):
		objectVertsWithCap.append(_vertsCap[i]+pos)
	
	#Create to new ArrayMesh
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = objectVertsWithCap
	arr[Mesh.ARRAY_TEX_UV] = objectUvsWithCap
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	
	#create Surface Material
	var material = SpatialMaterial.new()
	material.set_cull_mode(material.CULL_DISABLED)
	material.albedo_texture = texture;
	mesh.surface_set_material(0,material)

	#sets new collision
	_set_collision(objectVertsWithCap)

#Removes every vertecie until pos and uses createExtension to add back missing piece.
func deleteExtensionsFromMesh(pos):
	for i in range(_objectVerts.size()/(6*_vertsBase.size()),0,-1):
		if(_objectVerts[i*6*_vertsBase.size()-3].z>=pos.z):
			for _j in range(_vertsBase.size()*6):
				_objectVerts.remove(_objectVerts.size()-1)
				_objectUVs.remove(_objectVerts.size()-1)
	_lastToPos =  _objectVerts[_objectVerts.size()-3] - _vertsBase[_vertsBase.size()-1]
	addExtensionToMesh(createExtension(pos))
	
#Gets the center of an object for specifically its current z. Center is origin of the _vertsBase
func getPosFromZ(zPosition):
	for i in range(_objectVerts.size()/(6*(_vertsBase.size()))-2,-1,-1):
		if(_objectVerts[(i)*(6*_vertsBase.size())].z<zPosition):
			#Calculate slope for M=(x2-x1)/(z2-z1) and M=(y2-y1)/(z2-z1):
			#Calculate x=(x2-x1), y=(y2-y1) and z=(z2-z1)
			var currentPosition = _objectVerts[(i+1)*6*_vertsBase.size()] - _objectVerts[(i)*6*_vertsBase.size()]
			#Calculate x/z and y/z
			currentPosition /= currentPosition.z
			#Use slope to calculate relitive position inbetween 2 vertecies on z axis (relitive to position 1)
			currentPosition *= (zPosition-_objectVerts[(i)*6*_vertsBase.size()].z)
			#Add position 1 to get absolute position
			currentPosition += _objectVerts[(i)*6*_vertsBase.size()]
			#center position
			currentPosition -= _vertsBase[0]
			return currentPosition
	return Vector3(0,0,0)
	
#adds caps to the mesh. unused
#func capMesh(verts):
#	var capedMesh = []
#	capedMesh.append_array(verts)
#	var posBegin = verts[1] - _vertsBase[1]
#	for i in range(_vertsCap.size()):
#		capedMesh.append(_vertsCap[i]+posBegin)
#	var posEnd = (verts[verts.size()-3]-_vertsBase[_vertsBase.size()-1])
#	for i in range(_vertsCap.size()):
#		capedMesh.append(_vertsCap[i]+posEnd)
#	return capedMesh

#get mesh facing z axis from model
func _getCapMesh(mdt):
	var vertexZPosition = mdt.get_vertex(0).z
	var vertsBase = []
	var uvs = []
	for i in range(mdt.get_face_count()):
		var faceOnSameZ = true
		for j in range(3):
			if(mdt.get_vertex(mdt.get_face_vertex(i,j)).z == vertexZPosition):
				faceOnSameZ = false
		if(faceOnSameZ):
			vertsBase.append(mdt.get_vertex(mdt.get_face_vertex(i,0)))
			vertsBase.append(mdt.get_vertex(mdt.get_face_vertex(i,1)))
			vertsBase.append(mdt.get_vertex(mdt.get_face_vertex(i,2)))
			uvs.append(mdt.get_vertex_uv(mdt.get_face_vertex(i,0)))
			uvs.append(mdt.get_vertex_uv(mdt.get_face_vertex(i,1)))
			uvs.append(mdt.get_vertex_uv(mdt.get_face_vertex(i,2)))
	for i in range(vertsBase.size()):
		vertsBase[i].z=0
	_vertsCap = vertsBase
	_uvsCap = uvs

#get outline from  mesh facing z axis
func _getOutline(baseMesh):
	var connections = PoolVector2Array()
	var mdt_samez = MeshDataTool.new()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = baseMesh
	var tempMesh = ArrayMesh.new()
	tempMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mdt_samez.create_from_surface(tempMesh,0)
	
	var connectedVertecies = []
	connectedVertecies.resize(3)
	for i in range(mdt_samez.get_face_count()):
		for j in range(3):
			for k in range(baseMesh.size()):
				if(mdt_samez.get_vertex(mdt_samez.get_face_vertex(i,j))==baseMesh[k]):
					connectedVertecies[j] = k
					break

		connections.append(Vector2(connectedVertecies[0], connectedVertecies[1]))
		connections.append(Vector2(connectedVertecies[0], connectedVertecies[2]))
		connections.append(Vector2(connectedVertecies[1], connectedVertecies[2]))
	var pseudoi = connections.size()
	while(pseudoi>0):
		pseudoi = pseudoi - 1
		for j in range(pseudoi-1,-1,-1):
			if(connections[pseudoi].x==connections[j].x and connections[pseudoi].y==connections[j].y):
				connections.remove(pseudoi)
				connections.remove(j)
				pseudoi = pseudoi-1
				break
			if(connections[pseudoi].y==connections[j].x and connections[pseudoi].x==connections[j].y):
				connections.remove(pseudoi)
				connections.remove(j)
				pseudoi = pseudoi-1
				break
	var outline = []
	outline.append(0)
	for _i in range(connections.size()):
		for i in range(connections.size()):
			if(connections[i].x==outline[outline.size()-1] and (outline.size() <= 1 or connections[i].y!=outline[outline.size()-2])):
				outline.append(connections[i].y)
				break
			if(connections[i].y==outline[outline.size()-1] and (outline.size() <= 1 or connections[i].x!=outline[outline.size()-2])):
				outline.append(connections[i].x)
				break
	outline.remove(outline.size()-1)
	var outlineInBaseMesh = []
	outlineInBaseMesh.resize(baseMesh.size())
	for i in range(outline.size()):
		outlineInBaseMesh[outline[i]] = outline[(i+1)%outline.size()]
	return outlineInBaseMesh

#Sorts a baseMesh based on an outline. Sorted means connected vertecies are neighbors in array. Because this is an outline each vertex only has 2 connected vertecies
func _sortBaseMeshWithOutline(baseMesh, outline):
	var newBaseMesh = []
	var nextNumber = 0
	for _i in range(outline.size()):
		newBaseMesh.append(baseMesh[nextNumber])
		nextNumber = outline[nextNumber]
		if(nextNumber==0):
			break
	return newBaseMesh

#imports the uv coordinates from model for outline
func _getUvCoords(mdt, baseMesh):
	_uvcoords.resize(6*_vertsBase.size())
	var vertexZPosition = mdt.get_vertex(0).z
	for i in range(mdt.get_face_count()):
		for j in range(3):
			var vertex1 = mdt.get_face_vertex(i,j)
			var vertex2 = mdt.get_face_vertex(i,(j+1)%3)
			var vertex3 = mdt.get_face_vertex(i,(j+2)%3)
			if(mdt.get_vertex(vertex1).z == vertexZPosition and (mdt.get_vertex(vertex2).z != vertexZPosition or mdt.get_vertex(vertex3).z != vertexZPosition)):
				for k in range(baseMesh.size()):
					if(mdt.get_vertex(vertex1).x == baseMesh[k].x and mdt.get_vertex(vertex1).y == baseMesh[k].y):
						if(mdt.get_vertex(vertex1).x == mdt.get_vertex(vertex2).x and mdt.get_vertex(vertex1).y == mdt.get_vertex(vertex2).y):
							if(mdt.get_vertex(vertex3).x == baseMesh[(k-1)%baseMesh.size()].x and mdt.get_vertex(vertex3).y == baseMesh[(k-1)%baseMesh.size()].y):
								_uvcoords[k*6-6+1] = mdt.get_vertex_uv(vertex1)
								_uvcoords[k*6-6+5] = mdt.get_vertex_uv(vertex1)
								_uvcoords[k*6-6+2] = mdt.get_vertex_uv(vertex2)
								j = 4
							else:
								_uvcoords[k*6+4] = mdt.get_vertex_uv(vertex1)
								_uvcoords[k*6] = mdt.get_vertex_uv(vertex2)
								_uvcoords[k*6+3] = mdt.get_vertex_uv(vertex2)
								j = 4
						else: if(mdt.get_vertex(vertex1).x == mdt.get_vertex(vertex3).x and mdt.get_vertex(vertex1).y == mdt.get_vertex(vertex3).y):
							if(mdt.get_vertex(vertex2).x == baseMesh[(k-1)%baseMesh.size()].x and mdt.get_vertex(vertex2).y == baseMesh[(k-1)%baseMesh.size()].y):
								_uvcoords[k*6-6+1] = mdt.get_vertex_uv(vertex1)
								_uvcoords[k*6-6+5] = mdt.get_vertex_uv(vertex1)
								_uvcoords[k*6-6+2] = mdt.get_vertex_uv(vertex3)
								j = 4
							else:
								_uvcoords[(k*6+4)%_uvcoords.size()] = mdt.get_vertex_uv(vertex1)
								_uvcoords[(k*6)%_uvcoords.size()] = mdt.get_vertex_uv(vertex3)
								_uvcoords[(k*6+3)%_uvcoords.size()] = mdt.get_vertex_uv(vertex3)
								j = 4

#sets collisionShape of mesh to parameter. Parameter is visible mesh when object is finished
func _set_collision(var objectVertsWithCap):
	var shape = ConcavePolygonShape.new()
	shape.set_faces(objectVertsWithCap)
	_collisionShape.set_shape(shape)
	#ResourceSaver.save("res://col2.tres", shape) #used for debug
	
#creates a thin convexPolygonShape for physics simulations
func getPhysicsShape():
	var physicsShape = []
	physicsShape.append_array(_vertsBase)
	for i in range(_vertsBase.size()):
		physicsShape.append(_vertsBase[i] + Vector3(0,0,0.1))
	var returnedShape = ConvexPolygonShape.new()
	returnedShape.set_points(physicsShape)
	return returnedShape

#used for debug purposes
func safeExport():
	ResourceSaver.save("res://test.tres", mesh, 32)
