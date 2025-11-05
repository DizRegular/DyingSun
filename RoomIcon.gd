class_name RoomIcon
extends Node2D

# (เก็บตำแหน่งในตาราง)
var grid_pos = Vector2.ZERO 

# (Enum ใช้ในสคริปต์อื่นได้เลย เพราะมี class_name)
enum Biome { GRASSLAND, FOREST, MOUNTAIN }
enum Category { START, END, COMBAT, SUPPORT }

# ตัวแปรเก็บข้อมูลของห้องนี้
var room_biome = Biome.GRASSLAND
var room_category = Category.COMBAT
var connections = []
var is_player_here = false

# (ใหม่) "จำ" สีดั้งเดิม
var original_color = Color(1, 1, 1)

onready var icon_sprite = $IconSprite

func _ready():
	pass # (ไม่ต้องทำอะไร)

# ฟังก์ชันสำหรับตั้งค่าห้องนี้
func setup(category, biome):
	self.room_category = category
	self.room_biome = biome
	
	# (สำคัญ) เรา "บันทึก" สีดั้งเดิมลงในตัวแปร
	if category == Category.START:
		original_color = Color(0, 1, 0) # สีเขียว
	elif category == Category.END:
		original_color = Color(1, 0, 0) # สีแดง
	elif category == Category.SUPPORT:
		original_color = Color(1, 1, 0) # สีเหลือง
	else: # (COMBAT และอื่นๆ)
		original_color = Color(0.7, 0.3, 1.0) # สีม่วง
		
	# (ตั้งค่าสีเริ่มต้นเป็นสีดั้งเดิม)
	icon_sprite.modulate = original_color
