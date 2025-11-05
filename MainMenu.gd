extends Control

onready var parallax_bg = $ParallaxBackground

# (ถ้าไม่มีฟังก์ชัน _ready ก็ไม่ต้องใส่อันนี้)
func _ready():
	pass 

# ฟังก์ชันตรวจจับการเคลื่อนไหวของเมาส์
func _input(event):
	if event is InputEventMouseMotion:
		# ตรวจก่อนว่า parallax_bg ไม่ใช่ null
		if parallax_bg: 
			parallax_bg.scroll_offset.x = (event.position.x - get_viewport_rect().size.x / 2.0) * 100.0
			parallax_bg.scroll_offset.y = (event.position.y - get_viewport_rect().size.y / 2.0) * 100.0

# --- ฟังก์ชันของปุ่มต่างๆ ---

func _on_PlayButton_pressed():
	# !!! เปลี่ยน "res://GameScene.tscn" ให้เป็น Path Scene เกม !!!
	get_tree().change_scene("res://scenes/MapGenerator/MapScene.tscn")


func _on_SettingButton_pressed():
	# !!! เปลี่ยน "res://SettingMenu.tscn" ให้เป็น Path Scene Setting !!!
	get_tree().change_scene("res://scenes/MainMenu/SettingMenu.tscn")


func _on_ExitButton_pressed():
	get_tree().quit()
