extends Control

# ส่วนของ Volume
onready var volume_slider = $MarginContainer/VBoxContainer/VolumeSlider
onready var percentage_label = $MarginContainer/VBoxContainer/PercentageLabel

# ส่วนของ Brightness
onready var brightness_slider = $MarginContainer/VBoxContainer/BrightnessSlider
onready var brightness_percentage_label = $MarginContainer/VBoxContainer/BrightnessPercentageLabel


# ฟังก์ชัน _ready() จะถูกเรียกครั้งเดียวตอนเปิดหน้า Setting
func _ready():
	# --- ตั้งค่า Volume Slider ---
	# ตั้งค่า % เริ่มต้นให้ถูกต้อง
	_on_VolumeSlider_value_changed(volume_slider.value)
	
	# --- ตั้งค่า Brightness Slider ---
	# ดึงค่าที่เก็บไว้ใน SettingsManager มาใส่ใน Slider
	brightness_slider.value = SettingsManager.brightness
	# อัปเดต % ของ Brightness ทันที
	_on_BrightnessSlider_value_changed(brightness_slider.value)


# --- ฟังก์ชันที่เชื่อมต่อกับ Signals ---

# ถูกเรียกเมื่อเลื่อน Slider เสียง
func _on_VolumeSlider_value_changed(value):
	# 1. ปรับเสียง
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
	
	# 2. คำนวณเปอร์เซ็นต์ (จาก -20 ถึง 0 ให้เป็น 0% ถึง 100%)
	var percentage = round( (value + 20) / 20 * 100 )
	
	# 3. อัปเดตข้อความใน Label
	if percentage_label: # เช็คว่า Label มีอยู่จริง
		percentage_label.text = str(percentage) + "%"


# ถูกเรียกเมื่อเลื่อน Slider ความสว่าง
func _on_BrightnessSlider_value_changed(value):
	# 1. บอกให้ SettingsManager เปลี่ยนความสว่าง
	SettingsManager.set_brightness(value)
	
	# 2. คำนวณเปอร์เซ็นต์ (ค่า 0.5 - 1.5 จะกลายเป็น 50% - 150%)
	var percentage = round(value * 100)
	
	# 3. อัปเดตข้อความใน Label
	if brightness_percentage_label: # เช็คว่า Label มีอยู่จริง
		brightness_percentage_label.text = str(percentage) + "%"


# ถูกเรียกเมื่อกดปุ่ม Back
func _on_BackButton_pressed():
	get_tree().change_scene("res://scenes/MainMenu/MainMenu.tscn")
