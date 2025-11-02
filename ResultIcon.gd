# ResultIcon.gd
extends PanelContainer

# เชื่อมตัวแปรเข้ากับ Node ด้วย onready
onready var texture_rect = $VBoxContainer/ResultTexture
onready var name_label = $VBoxContainer/ResultName

# ฟังก์ชันนี้จะถูกเรียกจาก GachaScreen.gd
# เพื่อบอกว่าไอคอนนี้ต้องแสดงรูปอะไร ชื่ออะไร
func set_character_data(char_data):
	name_label.text = char_data.name
	texture_rect.texture = load(char_data.texture_path)
