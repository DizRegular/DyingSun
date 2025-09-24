extends Node2D

var save_path = "user://variable.save"

var VarName1 = 0
var VarName2 = 0
var VarName3 = 0
var VarName4 = 0
var VarName5 = 0

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_save_button_pressed()
	save()

func _on_save_button_pressed()
	load_data()

func save():
	var file = FileAccess.open(save_path, FileAcess.WRITE)
	file.store_var(VarName1)
	file.store_var(VarName2)
	file.store_var(VarName3)
	file.store_var(VarName4)
	file.store_var(VarName5)

func load_data():
	if FileAcess,file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		VarName1 = file.get_var(VarName1)
		VarName2 = file.get_var(VarName2)
		VarName3 = file.get_var(VarName3)
		VarName4 = file.get_var(VarName4)
		VarName5 = file.get_var(VarName5)
	else:
		print("no data saved...")
		VarName1 = 0
		VarName2 = 0
		VarName3 = 0
		VarName4 = 0
		VarName5 = 0
		
