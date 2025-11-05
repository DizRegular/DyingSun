# GachaScreen.gd
# โค้ดฉบับสมบูรณ์ (อัปเดตล่าสุด: ลบ Anton, UnnameHero)

extends Control

#=============================================================================
# 1. ตัวแปร และ ฐานข้อมูลตัวละคร
#=============================================================================

# (สำคัญ!) อย่าลืมลากไฟล์ ResultIcon.tscn มาใส่ใน Inspector ของ Node นี้
export (PackedScene) var result_icon_scene

# ค่าใช้จ่ายในการสุ่ม
const COST_PER_SUMMON = 10

# จำลอง Shards เริ่มต้น (ตั้งค่าไว้เยอะๆ เพื่อทดสอบ)
var player_shards = 500 

# --- ฐานข้อมูลตัวละคร (Companion Pool) ---
# Path: res://Asset/Companion/

# 1 ดาว: Korret, Emily, Lentum, Sasaki, Vastayan, Shielder
var pool_1_star = [
	{ "name": "Korret", "rarity": 1, "texture_path": "res://Asset/Companion/Korret.png" },
	{ "name": "Emily", "rarity": 1, "texture_path": "res://Asset/Companion/Emily.png" },
	{ "name": "Lentum", "rarity": 1, "texture_path": "res://Asset/Companion/Lentum.png" },
	{ "name": "Sasaki", "rarity": 1, "texture_path": "res://Asset/Companion/Sasaki.png" },
	{ "name": "Vastayan", "rarity": 1, "texture_path": "res://Asset/Companion/Vastayan.png" },
	{ "name": "Shielder", "rarity": 1, "texture_path": "res://Asset/Companion/Shielder.png" }
]

# 2 ดาว: Drauga, JinAhh, Daminos, Puppeteer
var pool_2_star = [
	{ "name": "Drauga", "rarity": 2, "texture_path": "res://Asset/Companion/Drauga.png" },
	{ "name": "JinAhh", "rarity": 2, "texture_path": "res://Asset/Companion/JinAhh.png" },
	{ "name": "Daminos", "rarity": 2, "texture_path": "res://Asset/Companion/Daminos.png" },
	{ "name": "Puppeteer", "rarity": 2, "texture_path": "res://Asset/Companion/Puppeteer.png" }
]

# 3 ดาว: Bakatof, Estella, Dullahan, Fauna
var pool_3_star = [
	{ "name": "Bakatof", "rarity": 3, "texture_path": "res://Asset/Companion/Bakatof.png" },
	{ "name": "Estella", "rarity": 3, "texture_path": "res://Asset/Companion/Estella.png" },
	{ "name": "Dullahan", "rarity": 3, "texture_path": "res://Asset/Companion/Dullahan.png" },
	{ "name": "Fauna", "rarity": 3, "texture_path": "res://Asset/Companion/fauna.png" } # (ระวัง 'f' ตัวพิมพ์เล็ก)
]


#=============================================================================
# 2. การเชื่อมต่อ Node (OnReady Vars)
#=============================================================================
# เชื่อมตัวแปรเข้ากับ Node ที่เราสร้างไว้ใน Scene
onready var shards_label = $VBoxContainer/PlayerShardsLabel
onready var summon_1_button = $VBoxContainer/Summon1Button
onready var summon_10_button = $VBoxContainer/Summon10Button

onready var result_1x_popup = $Result1xPopup
onready var result_1x_texture = $Result1xPopup/VBoxContainer/ResultTexture
onready var result_1x_name = $Result1xPopup/VBoxContainer/ResultName
onready var result_1x_close_button = $Result1xPopup/VBoxContainer/CloseButton

onready var result_10x_popup = $Result10xPopup
# --- อัปเดต Path นี้ ---
# (เนื่องจากเราเพิ่ม VBoxContainer เข้าไปครอบ ScrollContainer)
onready var result_grid = $Result10xPopup/VBoxContainer/ResultGrid

onready var error_dialog = $ErrorDialog


#=============================================================================
# 3. ฟังก์ชันเริ่มต้น (_ready)
#=============================================================================
# ฟังก์ชันนี้จะทำงานครั้งเดียวเมื่อเปิด Scene
func _ready():
	randomize() # สำคัญมาก: รีเซ็ตระบบสุ่มเพื่อให้ได้ผลลัพธ์ที่ "จริง"
	
	update_shards_label() # อัปเดต UI แสดง Shards ทันทีที่เปิดหน้า
	
	# เชื่อมต่อสัญญาณ (Signals) ของปุ่มต่างๆ เข้ากับฟังก์ชัน
	summon_1_button.connect("pressed", self, "_on_Summon1_pressed")
	summon_10_button.connect("pressed", self, "_on_Summon10_pressed")
	result_1x_close_button.connect("pressed", self, "_on_Close_1x_Popup_pressed")
	
	# --- เพิ่มการเชื่อมต่อปุ่มปิด 10x ---
	# (สมมติว่าคุณตั้งชื่อปุ่มว่า CloseButton10x ตามขั้นตอนที่แล้ว)
	$Result10xPopup/VBoxContainer/CloseButton10x.connect("pressed", self, "_on_Close_10x_Popup_pressed")


#=============================================================================
# 4. ตรรกะหลักของกาชา (Gacha Logic)
#=============================================================================

# ฟังก์ชันสุ่มตัวละคร 1 ตัว
func _perform_summon():
	# สุ่มตัวเลข 0.0 ถึง 1.0
	var roll = randf() 
	
	var chosen_pool = []
	
	# ตรวจสอบตามความน่าจะเป็น
	# 3 ดาว: 10% (โอกาส 0.0 ถึง 0.10)
	if roll < 0.10:
		chosen_pool = pool_3_star
	# 2 ดาว: 40% (โอกาส 0.10 ถึง 0.50)
	elif roll < 0.50: # (0.10 + 0.40)
		chosen_pool = pool_2_star
	# 1 ดาว: 50% (โอกาส 0.50 ถึง 1.0)
	else:
		chosen_pool = pool_1_star
		
	# สุ่มเลือกตัวละคร 1 ตัวจาก Pool ที่สุ่มได้
	var random_index = randi() % chosen_pool.size()
	var character_result = chosen_pool[random_index]
	
	# คืนค่าข้อมูลตัวละคร (Dictionary) ที่สุ่มได้
	return character_result


#=============================================================================
# 5. ฟังก์ชันที่เชื่อมต่อกับปุ่ม (Button Handlers)
#=============================================================================

# ฟังก์ชันนี้จะทำงานเมื่อกดปุ่ม "สุ่ม 1 ครั้ง"
func _on_Summon1_pressed():
	var cost = COST_PER_SUMMON
	
	# 1. ตรวจสอบว่ามี "shard of life" พอหรือไม่
	if player_shards < cost:
		show_error("Shard of Life ไม่เพียงพอ!") # แสดง Popup แจ้งเตือน
		return # หยุดฟังก์ชันทันที ไม่ทำต่อ
		
	# 2. หักเงิน (ถ้าโค้ดมาถึงตรงนี้ได้ แสดงว่าเงินพอ)
	player_shards -= cost
	update_shards_label()
	
	# 3. ทำการสุ่ม
	var result = _perform_summon()
	
	# (ในเกมจริง: ตรงนี้คือจุดที่คุณจะบันทึกตัวละครที่ได้เข้าสู่ปาร์ตี้ของผู้เล่น)
	# เช่น PlayerData.add_companion(result) 
	
	# 4. แสดงผลลัพธ์ (Output)
	show_1x_result(result)

# ฟังก์ชันนี้จะทำงานเมื่อกดปุ่ม "สุ่ม 10 ครั้ง"
func _on_Summon10_pressed():
	var cost = COST_PER_SUMMON * 10
	
	# 1. ตรวจสอบเงิน
	if player_shards < cost:
		show_error("Shard of Life ไม่เพียงพอ! (ต้องการ 100)")
		return
		
	# 2. หักเงิน
	player_shards -= cost
	update_shards_label()
	
	# 3. สุ่ม 10 ครั้ง
	var results_array = []
	for i in 10:
		var result = _perform_summon()
		results_array.append(result)
		# (ในเกมจริง: บันทึกตัวละครทั้ง 10 ตัวที่นี่)
		# PlayerData.add_companion(result)
	
	# 4. แสดงผลลัพธ์ 10 รายการ
	show_10x_result(results_array)


#=============================================================================
# 6. ฟังก์ชันช่วยเหลือ (Helper Functions)
#=============================================================================

# อัปเดต Label แสดงจำนวน Shard
func update_shards_label():
	shards_label.text = "Shards: " + str(player_shards)

# แสดงหน้าต่างสุ่ม 1 ครั้ง
func show_1x_result(char_data):
	result_1x_name.text = char_data.name
	result_1x_texture.texture = load(char_data.texture_path)
	result_1x_popup.popup_centered()

# ปิดหน้าต่างสุ่ม 1 ครั้ง (ถูกเรียกโดยปุ่ม CloseButton)
func _on_Close_1x_Popup_pressed():
	result_1x_popup.hide()

# แสดงหน้าต่างสุ่ม 10 ครั้ง
func show_10x_result(results):
	# 1. ล้างผลลัพธ์เก่าใน Grid ออกก่อน (ถ้ามี)
	# ใช้วิธีนี้เพื่อลบ Node ทันที ป้องกันปัญหา Timing
	while result_grid.get_child_count() > 0:
		var child = result_grid.get_child(0)
		result_grid.remove_child(child) # เอาออกจากตารางทันที
		child.free()                    # ลบออกจากหน่วยความจำทันที

	# 2. ตรวจสอบว่าลาก Scene Icon มาใส่หรือยัง
	if not result_icon_scene:
		# --- แก้ไขจาก print_error เป็น printerr ---
		printerr("ERROR: คุณยังไม่ได้ลาก ResultIcon.tscn มาใส่ใน Inspector ของ GachaScreen") 
		return
		
	# 3. สร้าง Icon 10 อันตามผลลัพธ์
	for char_data in results:
		var icon = result_icon_scene.instance() # สร้าง Scene 'ResultIcon.tscn' ขึ้นมา
		result_grid.add_child(icon) # เพิ่ม Icon เข้าไปในตาราง GridContainer
		
		# เรียกฟังก์ชัน 'set_character_data' ที่อยู่ใน ResultIcon.gd
		icon.set_character_data(char_data) 
		
	# 4. แสดง Popup
	result_10x_popup.popup_centered()

# --- เพิ่มฟังก์ชันนี้เข้ามา ---
# ฟังก์ชันนี้จะทำงานเมื่อกดปุ่ม "ปิด" ของหน้า 10 สุ่ม
func _on_Close_10x_Popup_pressed():
	result_10x_popup.hide()
	
# แสดงหน้าต่าง Error
func show_error(message):
	error_dialog.dialog_text = message
	error_dialog.popup_centered()
