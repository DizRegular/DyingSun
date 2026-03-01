extends Node2D

export (PackedScene) var room_icon_scene
export (PackedScene) var player_icon_scene

# (เราจะใช้ column_distance เป็นระยะห่างทั้ง X และ Y)
export var room_distance = 80 

onready var room_container = $RoomContainer
onready var line_container = $LineContainer
onready var camera = $Camera2D

var all_rooms = []
var start_room = null
var player = null
var ROOM_QUOTAS = {
	RoomIcon.Biome.GRASSLAND: 10,
	RoomIcon.Biome.FOREST: 15,
	RoomIcon.Biome.MOUNTAIN: 20
}

# --- Data Structures สำหรับ Grid ---
var grid = {} # Key: Vector2(x, y), Value: RoomIcon
var open_list = [] # ห้องที่ยังสามารถสร้างกิ่งต่อได้
var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

func _ready():
	randomize()
	generate_floor()
	spawn_player()

# --- (ฟังก์ชัน build_room_decks() เหมือนเดิมเป๊ะ) ---
func build_room_decks():
	var total_normal_rooms = 0
	var biome_deck = []
	for biome in ROOM_QUOTAS:
		var count = ROOM_QUOTAS[biome]
		total_normal_rooms += count
		for i in range(count):
			biome_deck.append(biome)
	biome_deck.shuffle()
	
	var category_deck = []
	var total_rooms_in_floor = total_normal_rooms + 2
	var min_support = int(total_rooms_in_floor * 0.2)
	var max_support = int(total_rooms_in_floor * 0.5)
	var support_count = randi() % (max_support - min_support + 1) + min_support
	var combat_count = total_normal_rooms - support_count
	
	for i in range(support_count):
		category_deck.append(RoomIcon.Category.SUPPORT)
	for i in range(combat_count):
		category_deck.append(RoomIcon.Category.COMBAT)
	category_deck.shuffle()
	
	return [biome_deck, category_deck]

# --- (ฟังก์ชัน create_room() เหมือนเดิมเป๊ะ) ---
func create_room(category, biome):
	var new_room = room_icon_scene.instance()
	room_container.add_child(new_room)
	new_room.setup(category, biome)
	return new_room

# --- ฟังก์ชันสร้างแผนที่ (อัลกอริทึมใหม่) ---
func generate_floor():
	var decks = build_room_decks()
	var biome_deck = decks[0]
	var category_deck = decks[1]
	
	all_rooms = []
	grid = {}
	open_list = []
	
	# --- 1. สร้างห้อง Start ---
	start_room = create_room(RoomIcon.Category.START, RoomIcon.Biome.GRASSLAND)
	start_room.grid_pos = Vector2.ZERO # ตำแหน่ง (0, 0)
	grid[Vector2.ZERO] = start_room
	open_list.append(start_room)
	all_rooms.append(start_room)
	
	var rooms_placed_count = 0
	var total_rooms_to_place = biome_deck.size()
	
	# --- 2. วนลูปสร้างห้อง (Random Walk) ---
	while rooms_placed_count < total_rooms_to_place and not open_list.empty():
		
		# สุ่มหยิบห้องจาก List (เพื่อให้มันแตกกิ่งแบบสุ่ม ไม่ใช่เรียงลำดับ)
		var current_room = open_list[randi() % open_list.size()]
		
		# สุ่มทิศทาง
		var valid_directions = []
		directions.shuffle() # สลับลำดับทิศทาง
		for dir in directions:
			var next_pos = current_room.grid_pos + dir
			if not grid.has(next_pos):
				valid_directions.append(dir)
				
		if valid_directions.empty():
			# ห้องนี้ตันแล้ว เอาออกจาก open_list
			open_list.erase(current_room)
		else:
			# ถ้ามีทางไปต่อ, สร้างห้องใหม่
			var dir = valid_directions[0] # เลือกทิศทางแรกที่สุ่มเจอ
			var next_pos = current_room.grid_pos + dir
			
			var biome = biome_deck.pop_back()
			var category = category_deck.pop_back()
			
			var new_room = create_room(category, biome)
			new_room.grid_pos = next_pos
			
			# บันทึกลง Grid และ List
			grid[next_pos] = new_room
			open_list.append(new_room)
			all_rooms.append(new_room)
			
			# --- เชื่อมต่อ (สำคัญมาก) ---
			current_room.connections.append(new_room)
			new_room.connections.append(current_room) # เชื่อมกลับ
			
			rooms_placed_count += 1

	# --- 3. สร้างห้อง End ---
	# หาห้องที่อยู่ "ทางตัน" (เชื่อมต่อแค่ 1 ห้อง) ที่ไม่ใช่ห้อง Start
	var dead_ends = []
	for room in all_rooms:
		if room.connections.size() == 1 and room != start_room:
			dead_ends.append(room)
			
	if dead_ends.empty():
		# (กันพลาด) ถ้าไม่มีทางตัน ให้ใช้ห้องสุดท้ายที่สร้าง
		dead_ends.append(all_rooms[all_rooms.size() - 1])
		
	var parent_for_end = dead_ends[randi() % dead_ends.size()]
	
	# พยายามหาที่วางห้อง End ที่ยังว่าง
	directions.shuffle()
	var end_pos = parent_for_end.grid_pos + directions[0]
	for dir in directions:
		end_pos = parent_for_end.grid_pos + dir
		if not grid.has(end_pos):
			break # เจอที่ว่าง
			
	var end_room = create_room(RoomIcon.Category.END, RoomIcon.Biome.GRASSLAND)
	end_room.grid_pos = end_pos
	grid[end_pos] = end_room
	all_rooms.append(end_room)
	
	parent_for_end.connections.append(end_room)
	end_room.connections.append(parent_for_end) # เชื่อมกลับ

	# --- 4. คำนวณตำแหน่งและวาดเส้น ---
	calculate_and_draw_layout()


# --- 4. ฟังก์ชันใหม่: คำนวณ Layout (ง่ายกว่าเดิม) และวาดเส้น ---
func calculate_and_draw_layout():
	# --- ลบเส้นเก่า (ถ้ามี) ---
	for line in line_container.get_children():
		line.queue_free()

	# --- (เพิ่ม) หาจุดกึ่งกลางจอ ---
	var screen_center = get_viewport_rect().size / 2

	# --- กำหนดตำแหน่งไอคอน ---
	for room in all_rooms:
		# (แก้ไขบรรทัดนี้: บวก screen_center เข้าไป)
		room.position = (room.grid_pos * room_distance) + screen_center
	
	# --- วาดเส้นเชื่อม ---
	# (โค้ดส่วนนี้เหมือนเดิม ไม่ต้องแก้)
	var drawn_connections = []
	for room in all_rooms:
		for connected_room in room.connections:
			var pair = [room, connected_room]
			pair.sort()
			if not drawn_connections.has(pair):
				draw_connection(room.position, connected_room.position)
				drawn_connections.append(pair)

# --- (ฟังก์ชัน draw_connection() เหมือนเดิมเป๊ะ) ---
func draw_connection(pos1, pos2):
	var line = Line2D.new()
	line.add_point(pos1)
	line.add_point(pos2)
	line.width = 3
	line.default_color = Color(1, 1, 1, 0.4)
	line_container.add_child(line)

# --- (ฟังก์ชัน spawn_player() เหมือนเดิมเป๊ะ) ---
func spawn_player():
	if player_icon_scene == null or start_room == null:
		print("ยังไม่ได้ตั้งค่า Player Scene หรือ Start Room")
		return
		
	player = player_icon_scene.instance()
	player.global_position = start_room.global_position
	player.current_room = start_room
	start_room.is_player_here = true
	add_child(player)

func _process(delta):
	if player != null: # <--- เช็คก่อนว่าผู้เล่นเกิดหรือยัง
		camera.global_position = player.global_position
