class_name RoomIcon
extends Node2D

var grid_pos = Vector2.ZERO 

# --- (Enum เก่า) ---
enum Biome { GRASSLAND, FOREST, MOUNTAIN }
enum Category { START, END, COMBAT, SUPPORT }

# --- ( ⭐️ ใหม่: สร้าง Enum สำหรับ Event 9 แบบ ⭐️ ) ---
# (นี่คือ "ประเภท" ของห้อง Event)
enum EventType {
	RUIN_CHEST,       # 1. ซากปรักหักพัง (หีบ)
	HOTEL,            # 2. โรงแรม/บาร์
	BLACKSMITH,       # 3. ช่างตีอาวุธ
	WIZARD_TOWER,     # 4. หอคอยพ่อมด
	ARCHERY_RANGE,    # 5. การฝึกระยะไกล
	GUILD,            # 6. กิลด์
	CASINO,           # 7. คาสิโน
	RUIN_TRAP_CHEST,  # 8. ซากปรักหักพัง (หีบกับดัก)
	ABYSS_SACRIFICE   # 9. เหว
}

# --- ตัวแปรสำหรับเก็บข้อมูลห้องนี้ ---
var room_biome = Biome.GRASSLAND
var room_category = Category.COMBAT
var room_event_type = null
var connections = []
var is_player_here = false

# -----------------------------------------------------------------
# --- ( ⭐️ โหลดรูปภาพทั้งหมด (สำคัญ!) ⭐️ ) ---

# --- ห้องพิเศษ ---
var tex_start = load("res://scenes/MapGenerator/rooms/UntitledArtwork8 - Layer 1.png")
var tex_end_boss = load("res://scenes/MapGenerator/rooms/Boss.png") # (ใช้รูป Boss)

# --- ห้อง Combat (ตามชั้น) ---
var tex_combat_grassland = load("res://scenes/MapGenerator/rooms/Grassland.png")
var tex_combat_forest = load("res://scenes/MapGenerator/rooms/Forrest.png")
var tex_combat_mountain = load("res://scenes/MapGenerator/rooms/Mountain.png")

# --- ห้อง Event (9 แบบ) ---
# (สำคัญ!) ลำดับใน Array นี้ ต้องตรงกับลำดับใน "enum EventType" เป๊ะๆ
var event_textures = [
	load("res://scenes/MapGenerator/rooms/Ruin.png"),      # 0 = RUIN_CHEST
	load("res://scenes/MapGenerator/rooms/Tower.png"),          # 1 = HOTEL
	load("res://scenes/MapGenerator/rooms/Arms shop.png"),     # 2 = BLACKSMITH
	load("res://scenes/MapGenerator/rooms/Tower.png"),   # 3 = WIZARD_TOWER
	load("res://scenes/MapGenerator/rooms/Archery range.png"),         # 4 = ARCHERY_RANGE
	load("res://scenes/MapGenerator/rooms/Guild.png"),           # 5 = GUILD
	load("res://scenes/MapGenerator/rooms/Casino.png"),          # 6 = CASINO
	load("res://scenes/MapGenerator/rooms/Ruin (Trap).png"),       # 7 = RUIN_TRAP_CHEST
	load("res://scenes/MapGenerator/rooms/Abyss.png")            # 8 = ABYSS_SACRIFICE
]
# -----------------------------------------------------------------

onready var icon_sprite = $IconSprite

func _ready():
	pass

# --- แก้ไขฟังก์ชัน setup ---
func setup(category, biome):
	self.room_category = category
	self.room_biome = biome
	self.room_event_type = null
	
	# (รีเซ็ตสี Modulate เริ่มต้น)
	icon_sprite.modulate = Color(1, 1, 1)
	
	# --- ตรรกะการ "เปลี่ยนรูป" ---
	if category == Category.START:
		icon_sprite.texture = tex_start
		
	elif category == Category.END:
		icon_sprite.texture = tex_end_boss
		
	elif category == Category.SUPPORT:
		# --- ห้อง Event/Support ---
		
		var random_event_id = randi() % EventType.size()
		
		self.room_event_type = random_event_id
		
		icon_sprite.texture = event_textures[random_event_id]
		# ------------------------------------------------
		
	else: # COMBAT
		
		# --- เปลี่ยนรูป Combat ตาม Biome ---
		if biome == Biome.GRASSLAND:
			icon_sprite.texture = tex_combat_grassland
		elif biome == Biome.FOREST:
			icon_sprite.texture = tex_combat_forest
		elif biome == Biome.MOUNTAIN:
			icon_sprite.texture = tex_combat_mountain
		else:
			icon_sprite.texture = tex_combat_grassland 

# ฟังก์ชันหรี่สี
func set_visited_state(visited):
	if visited:
		# หรี่สี รูปภาพลง 40%
		icon_sprite.modulate = Color(1, 1, 1).darkened(0.4)
	else:
		# สีปกติ สว่าง 100%
		icon_sprite.modulate = Color(1, 1, 1)
