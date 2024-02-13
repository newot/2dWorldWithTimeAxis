extends Spatial

#This script is used for:
#-setting the position of invisible walls at the beginning and end of worlds z axis

func _ready():
	var world = get_parent()
	get_child(0).transform.origin.z = world.DistanceBetweenTime
	get_child(1).transform.origin.z = world.maxZ

