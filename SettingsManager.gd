extends Node

# ค่าความสว่างเริ่มต้น (1.0 คือ ปกติ)
var brightness = 1.0

# ตัวแปรสำหรับเก็บโหนดที่ใช้ย้อมสีจอ
var canvas_modulate_node

# ฟังก์ชันนี้จะถูกเรียกเมื่อ Autoload นี้พร้อมใช้งาน
func _ready():
	# 1. สร้างโหนด CanvasModulate ขึ้นมา
	canvas_modulate_node = CanvasModulate.new()
	# 2. เพิ่มมันเข้าไปใน Scene Tree หลัก (เพื่อให้มันทำงานตลอด)
	get_tree().get_root().add_child(canvas_modulate_node)
	# 3. ตั้งค่าความสว่างเริ่มต้น
	set_brightness(brightness)

# ฟังก์ชันสำหรับให้ Scene อื่นเรียกใช้
func set_brightness(value):
	brightness = value
	
	if canvas_modulate_node:
		# เราจะเปลี่ยนสีของ CanvasModulate
		# Color(1, 1, 1) = สีขาว (สว่างปกติ)
		# Color(0.5, 0.5, 0.5) = สีเทา (มืดลง)
		# Color(1.5, 1.5, 1.5) = สว่างจ้า
		canvas_modulate_node.color = Color(brightness, brightness, brightness)
