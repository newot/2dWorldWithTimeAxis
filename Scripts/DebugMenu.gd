extends Panel

#This script is responsble for:
#-Throwing/moving an interactable object without selection arrow using a debug menu

#Currently unused

var test
var test2

func _ready():
	#test = get_parent().get_node("TemplateObject")
	#test2 = get_parent().get_node("TemplateObject/ObjectMesh")
	#test2 = get_parent().get_node("Static Objekt/Mesh")
	pass

func _on_Button_pressed():
	test.initiateCalc(Vector2(get_node("LineEdit").text.to_float(), get_node("LineEdit2").text.to_float()), get_node("LineEdit3").text.to_float())

func _on_Button2_pressed():
	test2.safeExport()
