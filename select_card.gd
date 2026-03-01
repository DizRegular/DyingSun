# TeamSelector.gd
extends Control

# --- ค่าคงที่ ---
const MAX_TEAM_SIZE = 3 # จำนวนเพื่อนร่วมทีมที่ต้องการ (ไม่รวมตัวเราเอง)

# ข้อมูล Stat ของเพื่อนร่วมทางทั้งหมด (รวม 20 คน)
const TEAMMATE_DATA = {
	"Teammate_A": {"HP": 100, "Mana": 50, "STR": 15, "DEX": 10, "INT": 20},
	"Teammate_B": {"HP": 110, "Mana": 40, "STR": 18, "DEX": 8, "INT": 15},
	"Teammate_C": {"HP": 90, "Mana": 60, "STR": 12, "DEX": 15, "INT": 25},
	"Teammate_D": {"HP": 80, "Mana": 70, "STR": 10, "DEX": 20, "INT": 30},
	"Teammate_E": {"HP": 120, "Mana": 30, "STR": 20, "DEX": 5, "INT": 10},
	"Teammate_F": {"HP": 95, "Mana": 55, "STR": 14, "DEX": 12, "INT": 22},
	"Teammate_G": {"HP": 105, "Mana": 45, "STR": 16, "DEX": 9, "INT": 17},
	"Teammate_H": {"HP": 115, "Mana": 35, "STR": 19, "DEX": 7, "INT": 12},
	"Teammate_I": {"HP": 85, "Mana": 65, "STR": 11, "DEX": 17, "INT": 28},
	"Teammate_J": {"HP": 75, "Mana": 75, "STR": 9, "DEX": 22, "INT": 32},
	"Teammate_K": {"HP": 102, "Mana": 48, "STR": 15, "DEX": 11, "INT": 19},
	"Teammate_L": {"HP": 108, "Mana": 42, "STR": 17, "DEX": 8, "INT": 16},
	"Teammate_M": {"HP": 92, "Mana": 58, "STR": 13, "DEX": 14, "INT": 24},
	"Teammate_N": {"HP": 82, "Mana": 68, "STR": 10, "DEX": 19, "INT": 29},
	"Teammate_O": {"HP": 122, "Mana": 28, "STR": 21, "DEX": 4, "INT": 9},
	"Teammate_P": {"HP": 97, "Mana": 53, "STR": 15, "DEX": 13, "INT": 21},
	"Teammate_Q": {"HP": 107, "Mana": 43, "STR": 17, "DEX": 10, "INT": 18},
	"Teammate_R": {"HP": 117, "Mana": 33, "STR": 20, "DEX": 6, "INT": 11},
	"Teammate_S": {"HP": 87, "Mana": 63, "STR": 12, "DEX": 16, "INT": 27},
	"Teammate_T": {"HP": 77, "Mana": 73, "STR": 9, "DEX": 21, "INT": 31}
}


# --- Node References (ต้องกำหนดใน Editor) ---
onready var teammates_container = $VBoxContainer/ScrollContainer/VBoxContainer # Container สำหรับรายชื่อ
onready var count_label = $VBoxContainer/HBoxContainer/Label # Label แสดงจำนวน
onready var confirm_button = $VBoxContainer/HBoxContainer/Button # ปุ่มยืนยัน

# Stat Pop-up Nodes
onready var stat_popup = $StatPopup # PopupDialog หลัก
onready var name_label = $StatPopup/VBoxContainer/NameLabel # Label สำหรับชื่อเพื่อนร่วมทาง
onready var stats_label = $StatPopup/VBoxContainer/StatsLabel # Label สำหรับแสดงค่า Stat
onready var close_button = $StatPopup/VBoxContainer/Button # ปุ่มปิด

# --- ตัวแปร ---
var selected_teammates = []

# --- ฟังก์ชันเริ่มต้น ---

func _ready():
	# 1. สร้างรายชื่อเพื่อนร่วมทีมทั้งหมดใน UI
	generate_teammate_list()
	
	# 2. อัปเดต UI เริ่มต้น
	update_ui()
	
	# 3. เชื่อมต่อ Signal ของปุ่ม
	confirm_button.connect("pressed", self, "_on_confirm_button_pressed")
	close_button.connect("pressed", stat_popup, "hide") # ให้ปุ่มปิดซ่อนหน้าต่าง Stat

# --- การสร้าง UI แบบ Dynamic ---

func generate_teammate_list():
	for name in TEAMMATE_DATA.keys():
		var teammate_data = TEAMMATE_DATA[name]
		
		# 1. สร้าง HBoxContainer สำหรับแถว (ปุ่มชื่อ + CheckBox)
		var row_container = HBoxContainer.new()
		row_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# 2. สร้าง Button สำหรับชื่อ (ใช้กดดู Stat)
		var name_button = Button.new()
		name_button.text = name
		name_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# เชื่อมต่อ Signal ของ Button เพื่อแสดง Stat
		# ใช้ 'name' และ 'teammate_data' เป็น Argument สำหรับ Signal
		name_button.connect("pressed", self, "_on_teammate_name_pressed", [name, teammate_data])
		
		# 3. สร้าง CheckBox สำหรับเลือกเข้าทีม
		var select_checkbox = CheckBox.new()
		select_checkbox.name = name # กำหนดชื่อ Node ให้ตรงกับชื่อ Teammate เพื่ออ้างอิง
		
		# เชื่อมต่อ Signal เมื่อมีการกดเลือก/ยกเลิก
		select_checkbox.connect("toggled", self, "_on_select_checkbox_toggled", [name, select_checkbox])
		
		# 4. เพิ่มเข้า Container
		row_container.add_child(name_button)
		row_container.add_child(select_checkbox)
		teammates_container.add_child(row_container)

# --- การจัดการ Input (เมื่อผู้ใช้กด CheckBox) ---

func _on_select_checkbox_toggled(pressed, teammate_name, checkbox):
	if pressed:
		# 1. ถ้าจำนวนที่เลือกยังไม่ถึง 3 คน ให้เพิ่มชื่อเข้ารายการ
		if selected_teammates.size() < MAX_TEAM_SIZE:
			selected_teammates.append(teammate_name)
		else:
			# 2. ถ้าเกิน 3 คนแล้ว ให้ยกเลิกการเลือกอันล่าสุด
			checkbox.set_pressed_no_signal(false)
			print("❌ เลือกเพื่อนร่วมทางได้สูงสุดแค่ ", MAX_TEAM_SIZE, " คนเท่านั้น!")
	else:
		# 3. ถ้าผู้ใช้ยกเลิกการเลือก ให้ลบชื่อออกจากรายการ
		if selected_teammates.has(teammate_name):
			selected_teammates.erase(teammate_name)
			
	update_ui()

# --- การจัดการ Input (เมื่อผู้ใช้กดปุ่มชื่อเพื่อดู Stat) ---

func _on_teammate_name_pressed(name, data):
	# 1. อัปเดต Label ใน PopupDialog
	name_label.text = "--- ข้อมูลเพื่อนร่วมทาง: %s ---" % name
	
	# จัดรูปแบบ Stat
	var stat_text = "HP: %d\n" % data["HP"]
	stat_text += "Mana: %d\n" % data["Mana"]
	stat_text += "STR (ความแข็งแกร่ง): %d\n" % data["STR"]
	stat_text += "DEX (ความว่องไว): %d\n" % data["DEX"]
	stat_text += "INT (สติปัญญา): %d" % data["INT"]
	
	stats_label.text = stat_text
	
	# 2. แสดง PopupDialog
	stat_popup.popup_centered()

# --- การอัปเดต UI (Label และ Button) ---

func update_ui():
	var current_count = selected_teammates.size()
	count_label.text = "ทีมที่เลือก: %d/%d" % [current_count, MAX_TEAM_SIZE]
	
	# ปุ่มยืนยันจะเปิดใช้งานเมื่อเลือกครบ 3 คนพอดี
	confirm_button.disabled = (current_count != MAX_TEAM_SIZE)
	
	# จัดการการปิดกั้น CheckBox (ตัวเลือกที่สี่เป็นต้นไป)
	var can_select_more = current_count < MAX_TEAM_SIZE
	
	# วนลูปผ่านทุกแถว (HBoxContainer) ใน Container
	for row_container in teammates_container.get_children():
		var checkbox = row_container.get_node_or_null(row_container.get_child(1).name) # หา CheckBox
		
		if checkbox and checkbox is CheckBox:
			# ถ้าเลือกเต็มแล้ว และ CheckBox นี้ยังไม่ได้ถูกเลือก
			if not can_select_more and not checkbox.is_pressed():
				checkbox.set_disabled(true)
			# ถ้ายังเลือกไม่เต็ม หรือ CheckBox นี้ถูกเลือกไปแล้ว
			else:
				checkbox.set_disabled(false)

# --- การยืนยัน (เมื่อกดปุ่ม) ---

func _on_confirm_button_pressed():
	if selected_teammates.size() == MAX_TEAM_SIZE:
		print("✅ ทีมที่เลือกสำเร็จแล้ว:")
		print("เพื่อนร่วมทาง: ", selected_teammates)
		# **โค้ดถัดไป:** คุณสามารถเรียกฟังก์ชันเพื่อเริ่มเกม หรือเปลี่ยน Scene ได้ที่นี่
		# get_tree().change_scene("res://game_world.tscn")
	else:
		# (อันนี้ไม่น่าจะเกิดขึ้นเพราะปุ่มถูกปิดกั้นอยู่แล้ว)
		print("โปรดเลือกเพื่อนร่วมทางให้ครบ ", MAX_TEAM_SIZE, " คน")
