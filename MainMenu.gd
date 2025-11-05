extends Control

onready var parallax_bg = $ParallaxBackground

func _ready():
	pass 

func _input(event):
	if event is InputEventMouseMotion:
		if parallax_bg: 
			parallax_bg.scroll_offset.x = (event.position.x - get_viewport_rect().size.x / 2.0) * 100.0
			parallax_bg.scroll_offset.y = (event.position.y - get_viewport_rect().size.y / 2.0) * 100.0


func _on_PlayButton_pressed():
	get_tree().change_scene("res://scenes/MapGenerator/MapScene.tscn")


func _on_SettingButton_pressed():
	get_tree().change_scene("res://scenes/MainMenu/SettingMenu.tscn")


func _on_ExitButton_pressed():
	get_tree().quit()
