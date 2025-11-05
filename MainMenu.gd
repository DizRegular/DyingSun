extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var parallax_bg = $ParallaxBackground

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_PlayButton_pressed():
	# เปลี่ยน "res://GameScene.tscn" ให้เป็น Path ของ Scene เกมของคุณ
	get_tree().change_scene("res://GameScene.tscn")


func _on_SettingButton_pressed():
	# เปลี่ยน "res://SettingMenu.tscn" ให้เป็น Path ของ Scene Setting ที่เราเพิ่งสร้าง
	get_tree().change_scene("res://scenes/MainMenu/SettingMenu.tscn")


func _on_ExitButton_pressed():
	# คำสั่งให้ออกจากเกม
	get_tree().quit()

func _input(event):
	if event is InputEventMouseMotion:
		# เราจะใช้ค่า x และ y ของเมาส์ เพื่อเป็นตัวขับเคลื่อน Parallax
		# event.position คือตำแหน่งเมาส์บนหน้าจอ
		# get_viewport_rect().size คือขนาดหน้าจอ
		# / 2.0 เพื่อให้จุดกึ่งกลางของจอเป็นจุด "หยุดนิ่ง"
		# * 100.0 คือค่าตัวคูณ เพื่อให้มันขยับได้เยอะขึ้น
		parallax_bg.scroll_offset.x = (event.position.x - get_viewport_rect().size.x / 2.0) * 100.0
		parallax_bg.scroll_offset.y = (event.position.y - get_viewport_rect().size.y / 2.0) * 100.0
