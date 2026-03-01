extends Node2D

# ห้องที่ผู้เล่น "ยืนอยู่" ปัจจุบัน
var current_room = null

# (เราไม่ต้องใช้ _physics_process, speed, หรือ target_room อีกแล้ว)

# เราจะใช้ _unhandled_input เพื่อรับการกดปุ่มแค่ครั้งเดียว
# (Input Map ของคุณ: ui_right, ui_left, ui_up, ui_down)
func _unhandled_input(event):
	if current_room == null:
		return

	var target = null

	# 1. ตรวจสอบการกดปุ่ม
	if event.is_action_pressed("ui_right"): # <--- แก้ไข
		target = find_connected_room_in_direction(Vector2.RIGHT)
	elif event.is_action_pressed("ui_left"): # <--- แก้ไข
		target = find_connected_room_in_direction(Vector2.LEFT)
	elif event.is_action_pressed("ui_up"): # <--- แก้ไข
		target = find_connected_room_in_direction(Vector2.UP)
	elif event.is_action_pressed("ui_down"): # <--- แก้ไข
		target = find_connected_room_in_direction(Vector2.DOWN)

	# 2. ถ้าเจอห้องเป้าหมาย ให้พยายามเข้า
	if target != null:
		try_to_enter_room(target)
		get_tree().set_input_as_handled()


# ฟังก์ชันใหม่: ค้นหาห้องที่เชื่อมต่อในทิศทางที่กำหนด
func find_connected_room_in_direction(direction_vector):
	var best_target = null
	var best_score = -INF # ใช้ -INF (ลบอนันต์) เพื่อให้ค่าบวกใดๆ ดีกว่าเสมอ
	
	var current_pos = current_room.global_position
	
	# วนลูปดูห้องที่เชื่อมต่อกับห้องปัจจุบันเท่านั้น
	for room in current_room.connections:
		var room_pos = room.global_position
		
		# คำนวณ Vector จากปัจจุบัน ไปยังห้องที่เชื่อมต่อ
		var diff_vector = (room_pos - current_pos).normalized()
		
		# คำนวณ "Dot Product" เพื่อดูว่าทิศทางตรงกันแค่ไหน
		# (ค่า 1 = ทิศเดียวกันเป๊ะ, ค่า 0 = ตั้งฉาก, ค่า -1 = ตรงข้าม)
		var score = diff_vector.dot(direction_vector)
		
		# เราต้องการห้องที่ "ค่อนข้าง" ไปในทิศทางนั้น (score > 0.5)
		# และเป็นห้องที่ดีที่สุด (score > best_score)
		if score > 0.5 and score > best_score:
			best_score = score
			best_target = room
			
	return best_target


# ฟังก์ชันนี้ยังคงสำคัญมาก แต่เราจะ "snap" (วาร์ป) ตำแหน่งทันที
func try_to_enter_room(room_to_enter):
	
	# --- 1. เช็คว่าใช่ห้องเดิมที่อยู่หรือเปล่า ---
	if room_to_enter == current_room:
		return # ไม่ต้องทำอะไร

	# --- 2. เช็คว่าเชื่อมต่อหรือไม่ ---
	if current_room.connections.has(room_to_enter):
		# --- สำเร็จ! เข้าห้องได้ ---
		print("เข้าห้องสำเร็จ: ", room_to_enter.name)
		
		# อัปเดตสถานะห้อง (ย้อมสี)
		if current_room != null:
			current_room.is_player_here = false
			current_room.modulate = Color(0.5, 0.5, 0.5) # สีเทา (ห้องเก่า)
		
		room_to_enter.is_player_here = true
		room_to_enter.modulate = Color(1, 1, 1) # สีขาว (ห้องปัจจุบัน)
		
		# อัปเดตตำแหน่งผู้เล่น
		self.current_room = room_to_enter
		
		# --- (สำคัญ) ย้ายตำแหน่งผู้เล่นทันที ---
		self.global_position = current_room.global_position
		
		# --- ณ จุดนี้ คือจุดที่คุณจะสลับ Scene ไปยังห้องต่อสู้/สนับสนุน ---
		# if room_to_enter.room_category == RoomIcon.Category.COMBAT:
		#	  get_tree().change_scene("res://Scenes/CombatScene.tscn")
		# elif room_to_enter.room_category == RoomIcon.Category.SUPPORT:
		#	  get_tree().change_scene("res://Scenes/SupportScene.tscn")
		
	else:
		# --- 3. ไม่ใช่ห้องเดิม และไม่ได้เชื่อมต่อ ---
		print("เข้าห้องไม่ได้! (ไม่ได้เชื่อมต่อ)")
