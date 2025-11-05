class_name RoomIcon
extends Node2D

var grid_pos = Vector2.ZERO # เก็บตำแหน่งในตาราง

# ประเภทของห้อง (Biome)
enum Biome { GRASSLAND, FOREST, MOUNTAIN }
# หมวดหมู่ของห้อง
enum Category { START, END, COMBAT, SUPPORT }

# ตัวแปรเก็บข้อมูลของห้องนี้
var room_biome = Biome.GRASSLAND
var room_category = Category.COMBAT

# เก็บว่าห้องนี้เชื่อมต่อกับห้องไหนบ้าง (เก็บ Node ของห้องถัดไป)
var connections = []
# เก็บว่าผู้เล่นอยู่ที่ห้องนี้หรือไม่
var is_player_here = false

# โหนดลูก
onready var icon_sprite = $IconSprite

func _ready():
	# (โค้ดที่เชื่อมต่อกับ Detector ถูกลบออกไปแล้ว)
	pass

# ฟังก์ชันสำหรับตั้งค่าห้องนี้ (จะถูกเรียกโดย MapGenerator)
func setup(category, biome):
	self.room_category = category
	self.room_biome = biome
	
	# --- ส่วนนี้สำหรับเปลี่ยนรูปไอคอนตามประเภท ---
	# (ต้องแน่ใจว่า Sprite ของคุณเป็น "สีขาว")
	if category == Category.START:
		icon_sprite.modulate = Color(0, 1, 0) # สีเขียว
	elif category == Category.END:
		icon_sprite.modulate = Color(1, 0, 0) # สีแดง
	elif category == Category.SUPPORT:
		icon_sprite.modulate = Color(1, 1, 0) # สีเหลือง
	else: 
		# (ห้อง COMBAT และอื่นๆ)
		icon_sprite.modulate = Color(0.7, 0.3, 1.0) # สีม่วง
