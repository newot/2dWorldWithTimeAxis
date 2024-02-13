extends Panel

#This script is responsible for:
#-hiding and showing infobox

func _physics_process(_delta):
	if Input.is_action_just_pressed("hide_show_infobox"):
		if visible:
			visible = false
		else:
			visible = true
