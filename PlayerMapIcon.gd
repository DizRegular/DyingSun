extends Node2D

# Signal ที่จะส่งกลับไปให้ MapGenerator
signal next_floor_requested
signal prev_floor_requested

var current_room = null

# (ใช้ _unhandled_input เพื่อให้คลิกเม้าส์ไม่ขัดจังหวะ)
func _unhandled_input(event):
	if current_room == null:
		return

	var target = null

	# --- 1. ตรวจสอบการ "เดิน" (Snap-to-node) ---
	if event.is_action_pressed("ui_right"):
		target = find_connected_room_in_direction(Vector2.RIGHT)
	elif event.is_action_pressed("ui_left"):
		target = find_connected_room_in_direction(Vector2.LEFT)
	elif event.is_action_pressed("ui_up"):
		target = find_connected_room_in_direction(Vector2.UP)
	elif event.is_action_pressed("ui_down"):
		target = find_connected_room_in_direction(Vector2.DOWN)

	if target != null:
		try_to_enter_room(target)
		get_tree().set_input_as_handled() # (หยุด Input ไม่ให้ค้าง)
		return # (ถ้าเดินแล้ว ไม่ต้อง Interact ต่อ)

	# --- 2. ตรวจสอบการ "Interact" (ปุ่ม E) ---
	# (ต้องใช้ Input.is_action_just_pressed ไม่ใช่ event)
	if Input.is_action_just_pressed("interact"):
		interact_with_current_room()
		get_tree().set_input_as_handled()


# (ฟังก์ชันใหม่สำหรับปุ่ม E)
func interact_with_current_room():
	if current_room == null:
		return
	
	if current_room.room_category == RoomIcon.Category.END:
		emit_signal("next_floor_requested")
	elif current_room.room_category == RoomIcon.Category.START:
		emit_signal("prev_floor_requested")


# (ฟังก์ชันหาห้องในทิศทางที่กด)
func find_connected_room_in_direction(direction_vector):
	var best_target = null
	var best_score = -INF
	
	var current_pos = current_room.global_position
	
	for room in current_room.connections:
		var room_pos = room.global_position
		var diff_vector = (room_pos - current_pos).normalized()
		var score = diff_vector.dot(direction_vector)
		
		# (score > 0.5 คือต้องค่อนข้างตรงทิศทาง)
		if score > 0.5 and score > best_score:
			best_score = score
			best_target = room
			
	return best_target


# (ฟังก์ชันพยายามเข้าห้อง)
func try_to_enter_room(room_to_enter):
	
	if room_to_enter == current_room:
		return # (กันการเข้าห้องที่ยืนอยู่)

	if current_room.connections.has(room_to_enter):
		print("เข้าห้องสำเร็จ: ", room_to_enter.name)
		
		# --- (1. "รายงาน" MapGenerator ว่าห้องนี้ถูกเยี่ยมแล้ว) ---
		if current_room != null:
			var map_generator = get_parent() 
			if map_generator.has_method("mark_room_as_visited"):
				var current_floor_index = map_generator.current_floor
				# บอก MapGenerator ให้ "จำ" ห้องนี้ไว้
				map_generator.mark_room_as_visited(current_floor_index, current_room.grid_pos)
		
		# --- (2. ตรรกะการเปลี่ยนสี (ใช้สีทึบ) ) ---
		if current_room != null:
			current_room.is_player_here = false
			# (เอาสีดั้งเดิมมา "หรี่ลง" 40%)
			current_room.icon_sprite.modulate = current_room.original_color.darkened(0.4)
		
		room_to_enter.is_player_here = true
		# (เราลบโค้ดที่ทำให้ห้องใหม่เป็น "สีขาว" ออกแล้ว)
		# ----------------------------------------------
		
		# อัปเดตสถานะและ "Snap" ตำแหน่ง
		self.current_room = room_to_enter
		self.global_position = current_room.global_position
		
		# (จุดนี้คือจุดที่จะสลับไป Scene ต่อสู้)
		# if room_to_enter.room_category == RoomIcon.Category.COMBAT:
		#	  get_tree().change_scene("res://Scenes/CombatScene.tscn")
		
	else:
		print("เข้าห้องไม่ได้! (ไม่ได้เชื่อมต่อ)")
