extends Node2D

# -----------------------------------------------------------------
# --- Export Variables ---
# -----------------------------------------------------------------
export (PackedScene) var room_icon_scene
export (PackedScene) var player_icon_scene
export var room_distance = 100 

# -----------------------------------------------------------------
# --- OnReady Variables ---
# -----------------------------------------------------------------
onready var room_container = $RoomContainer
onready var line_container = $LineContainer
onready var camera = $Camera2D 

# -----------------------------------------------------------------
# --- Class Variables ---
# -----------------------------------------------------------------
var all_rooms = []
var start_room = null
var end_room = null
var player = null

# --- กำหนดค่าตายตัวสำหรับแต่ละชั้น ---
var FLOOR_CONFIG = {
	1: { "biome": RoomIcon.Biome.GRASSLAND, "count": 10 },
	2: { "biome": RoomIcon.Biome.FOREST,    "count": 15 },
	3: { "biome": RoomIcon.Biome.MOUNTAIN,  "count": 20 }
}

# Data สำหรับ Grid Generation
var grid = {}
var open_list = []
var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

# Data สำหรับ Floor Management
var current_floor = 1
var floor_seeds = [] 
var visited_rooms_by_floor = {}

# -----------------------------------------------------------------
# --- Godot Core Functions ---
# -----------------------------------------------------------------

func _ready():
	randomize() 
	spawn_player()
	load_floor(1, "start")

func _process(delta):
	if player != null: 
		camera.global_position = player.global_position

# -----------------------------------------------------------------
# --- Player & Floor Management ---
# -----------------------------------------------------------------

func spawn_player():
	if player_icon_scene == null:
		print("Player scene not set in Inspector")
		return
	player = player_icon_scene.instance()
	add_child(player)
	player.connect("next_floor_requested", self, "go_to_next_floor")
	player.connect("prev_floor_requested", self, "go_to_prev_floor")

func go_to_next_floor():
	if current_floor >= 3:
		print("สุดทางแล้ว! (Max floor reached)")
		return 
	load_floor(current_floor + 1, "start")

func go_to_prev_floor():
	if current_floor > 1: 
		load_floor(current_floor - 1, "end") 
	else:
		print("อยู่ที่ชั้นแรกสุดแล้ว! (Floor 1)")

func clear_floor():
	for room in all_rooms:
		room.queue_free()
	all_rooms.clear()
	for line in line_container.get_children():
		line.queue_free()
	grid.clear()
	open_list.clear()
	
func mark_room_as_visited(floor_idx, room_grid_pos):
	if not visited_rooms_by_floor.has(floor_idx):
		visited_rooms_by_floor[floor_idx] = [] 
	if not visited_rooms_by_floor[floor_idx].has(room_grid_pos):
		visited_rooms_by_floor[floor_idx].append(room_grid_pos)

func load_floor(floor_index, spawn_at = "start"):
	clear_floor()
	current_floor = floor_index
	
	var seed_index = floor_index - 1 
	var floor_seed
	if seed_index < floor_seeds.size():
		floor_seed = floor_seeds[seed_index] 
	else:
		floor_seed = randi() 
		floor_seeds.append(floor_seed) 
		
	print("Loading Floor: ", floor_index, " with Seed: ", floor_seed)
	seed(floor_seed)
	
	start_room = null
	end_room = null
	generate_floor() 
	
	if visited_rooms_by_floor.has(floor_index):
		var visited_list = visited_rooms_by_floor[floor_index]
		for room in all_rooms:
			if visited_list.has(room.grid_pos):
				room.set_visited_state(true) # หรี่สี
	
	var spawn_room = null
	if spawn_at == "start":
		spawn_room = start_room
	else: 
		spawn_room = end_room
		
	if player != null and spawn_room != null:
		player.global_position = spawn_room.global_position
		player.current_room = spawn_room
		spawn_room.is_player_here = true
		spawn_room.set_visited_state(false) # ห้องสว่าง
	else:
		print("ERROR: ไม่พบ Player หรือ Spawn Room ตอนโหลดชั้น!")

# -----------------------------------------------------------------
# --- Map Generation Logic ---
# -----------------------------------------------------------------

func build_room_decks():
	if not FLOOR_CONFIG.has(current_floor):
		print("ERROR: ไม่พบค่ากำหนดสำหรับชั้น ", current_floor)
		return [[], []] 

	var config = FLOOR_CONFIG[current_floor]
	var biome = config["biome"]
	var count = config["count"] 

	var biome_deck = []
	for i in range(count):
		biome_deck.append(biome) 

	var total_normal_rooms = count
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

func create_room(category, biome):
	var new_room = room_icon_scene.instance()
	room_container.add_child(new_room)
	new_room.setup(category, biome)
	return new_room

func generate_floor():
	var decks = build_room_decks()
	var biome_deck = decks[0]
	var category_deck = decks[1]
	
	if biome_deck.empty():
		print("ERROR: Decks ว่างเปล่า, หยุดการสร้างชั้น")
		return

	start_room = create_room(RoomIcon.Category.START, RoomIcon.Biome.GRASSLAND)
	start_room.grid_pos = Vector2.ZERO
	grid[Vector2.ZERO] = start_room
	open_list.append(start_room)
	all_rooms.append(start_room)
	
	var rooms_placed_count = 0
	var total_rooms_to_place = biome_deck.size()
	
	while rooms_placed_count < total_rooms_to_place and not open_list.empty():
		var current_room = open_list[randi() % open_list.size()]
		var shuffled_dirs = directions.duplicate()
		shuffled_dirs.shuffle()
		var valid_directions = []
		for dir in shuffled_dirs:
			var next_pos = current_room.grid_pos + dir
			if not grid.has(next_pos):
				valid_directions.append(dir)
		if valid_directions.empty():
			open_list.erase(current_room)
		else:
			var dir = valid_directions[0] 
			var next_pos = current_room.grid_pos + dir
			if biome_deck.empty(): break 
			
			var biome = biome_deck.pop_back() 
			var category = category_deck.pop_back()
			var new_room = create_room(category, biome) 
			
			new_room.grid_pos = next_pos
			grid[next_pos] = new_room
			open_list.append(new_room)
			all_rooms.append(new_room)
			current_room.connections.append(new_room)
			new_room.connections.append(current_room)
			rooms_placed_count += 1

	var dead_ends = []
	for room in all_rooms:
		if room.connections.size() == 1 and room != start_room:
			dead_ends.append(room)
	if dead_ends.empty():
		dead_ends.append(all_rooms[all_rooms.size() - 1])
	var parent_for_end = dead_ends[randi() % dead_ends.size()]
	
	var shuffled_dirs_end = directions.duplicate()
	shuffled_dirs_end.shuffle()
	var end_pos = parent_for_end.grid_pos + shuffled_dirs_end[0]
	for dir in shuffled_dirs_end:
		end_pos = parent_for_end.grid_pos + dir
		if not grid.has(end_pos):
			break 
	
	end_room = create_room(RoomIcon.Category.END, RoomIcon.Biome.GRASSLAND)
	end_room.grid_pos = end_pos
	grid[end_pos] = end_room
	all_rooms.append(end_room)
	parent_for_end.connections.append(end_room)
	end_room.connections.append(parent_for_end) 

	calculate_and_draw_layout()

# -----------------------------------------------------------------
# --- Drawing Functions ---
# -----------------------------------------------------------------

func calculate_and_draw_layout():
	for line in line_container.get_children():
		line.queue_free()

	var screen_center = get_viewport_rect().size / 2

	for room in all_rooms:
		room.position = (room.grid_pos * room_distance) + screen_center
	
	var drawn_connections = [] 
	for room in all_rooms:
		for connected_room in room.connections:
			var pair = [room, connected_room]
			pair.sort() 
			if not drawn_connections.has(pair):
				draw_connection(room.position, connected_room.position)
				drawn_connections.append(pair)

func draw_connection(pos1, pos2):
	var line = Line2D.new()
	line.add_point(pos1)
	line.add_point(pos2)
	line.width = 3
	line.default_color = Color(1, 1, 1, 0.4)
	line_container.add_child(line)
