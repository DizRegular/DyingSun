extends Node2D

# Signal MapGenerator
signal next_floor_requested
signal prev_floor_requested

var current_room = null

func _unhandled_input(event):
	if current_room == null:
		return

	var target = null

	# --- ตรวจสอบการ เดิน ---
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
		get_tree().set_input_as_handled() 
		return 

	# --- ตรวจสอบการ Interact ---
	if Input.is_action_just_pressed("interact"):
		interact_with_current_room()
		get_tree().set_input_as_handled()

func interact_with_current_room():
	if current_room == null:
		return
	if current_room.room_category == RoomIcon.Category.END:
		emit_signal("next_floor_requested")
	elif current_room.room_category == RoomIcon.Category.START:
		emit_signal("prev_floor_requested")

func find_connected_room_in_direction(direction_vector):
	var best_target = null
	var best_score = -INF
	var current_pos = current_room.global_position
	
	for room in current_room.connections:
		var room_pos = room.global_position
		var diff_vector = (room_pos - current_pos).normalized()
		var score = diff_vector.dot(direction_vector)
		
		if score > 0.5 and score > best_score:
			best_score = score
			best_target = room
			
	return best_target

func try_to_enter_room(room_to_enter):
	
	if room_to_enter == current_room:
		return

	if current_room.connections.has(room_to_enter):
		print("เข้าห้องสำเร็จ: ", room_to_enter.name)
		
		# --- บอก MapGenerator ว่าห้องนี้ถูกเข้าแล้ว ---
		if current_room != null:
			var map_generator = get_parent() 
			if map_generator.has_method("mark_room_as_visited"):
				var current_floor_index = map_generator.current_floor
				map_generator.mark_room_as_visited(current_floor_index, current_room.grid_pos)
		
		# --- set_visited_state ---
		if current_room != null:
			current_room.is_player_here = false
			current_room.set_visited_state(true)
		
		room_to_enter.is_player_here = true
		room_to_enter.set_visited_state(false)
		# ----------------------------------------------
		
		# อัปเดตสถานะและ Snap ตำแหน่ง
		self.current_room = room_to_enter
		self.global_position = current_room.global_position
	else:
		print("เข้าห้องไม่ได้! (ไม่ได้เชื่อมต่อ)")
