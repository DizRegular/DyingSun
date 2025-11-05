extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var volume_slider = $MarginContainer/VBoxContainer/VolumeSlider
onready var percentage_label = $MarginContainer/VBoxContainer/PercentageLabel
onready var brightness_slider = $MarginContainer/VBoxContainer/BrightnessSlider
onready var brightness_percentage_label = $MarginContainer/VBoxContainer/BrightnessPercentageLabel
# Called when the node enters the scene tree for the first time.
func _ready():
	# เรียกฟังก์ชัน value_changed ด้วยตนเอง 1 ครั้ง
	# เพื่อตั้งค่า % เริ่มต้นให้ถูกต้อง
	_on_VolumeSlider_value_changed(volume_slider.value)
	# ดึงค่าที่เก็บไว้ใน SettingsManager มาใส่ใน Slider
	brightness_slider.value = SettingsManager.brightness
	# อัปเดต % ของ Brightness ทันที
	_on_BrightnessSlider_value_changed(brightness_slider.value)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_VolumeSlider_value_changed(value):
	# 1. ปรับเสียง
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
	
	# 2. คำนวณเปอร์เซ็นต์
	var percentage = round( (value + 20) / 20 * 100 )
	
	# 3. อัปเดตข้อความใน Label
	percentage_label.text = str(percentage) + "%"

func _on_BackButton_pressed():
	# เปลี่ยน "res://MainMenu.tscn" ให้เป็น Path ของ Main Menu ของคุณ
	get_tree().change_scene("res://scenes/MainMenu/MainMenu.tscn")


func _on_BrightnessSlider_value_changed(value):
	# 1. บอกให้ SettingsManager เปลี่ยนความสว่าง
	SettingsManager.set_brightness(value)
	
	# 2. คำนวณเปอร์เซ็นต์ (ค่า 0.5 - 1.5 จะกลายเป็น 50% - 150%)
	var percentage = round(value * 100)
	
	# 3. อัปเดตข้อความใน Label
	brightness_percentage_label.text = str(percentage) + "%"
