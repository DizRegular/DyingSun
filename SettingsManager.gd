extends Node

# ค่าความสว่างเริ่มต้น
var brightness = 1.0

# ตัวแปรสำหรับเก็บโหนดสีจอ
var canvas_modulate_node

# ฟังก์ชันนี้จะถูกเรียกเมื่อ Autoload นี้พร้อมใช้งาน
func _ready():
	#สร้างโหนด CanvasModulate ขึ้นมา
	canvas_modulate_node = CanvasModulate.new()
	
	#เพิ่มเข้าไปใน Scene Tree
	get_tree().get_root().call_deferred("add_child", canvas_modulate_node) 
	
	#ตั้งค่าความสว่างเริ่มต้น
	set_brightness(brightness)

# ฟังก์ชันสำหรับให้ Scene อื่นเรียกใช้
func set_brightness(value):
	brightness = value
	
	if canvas_modulate_node:
		# เปลี่ยนสีของ CanvasModulate
		canvas_modulate_node.color = Color(brightness, brightness, brightness)
