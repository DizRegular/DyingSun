extends KinematicBody2D
class_name Unit

# Enum for unit class. This will be a dropdown in the Inspector.
enum UnitClass { WARRIOR, ARCHER, WIZARD, SUPPORT }

# --- Unit Stats ---
export(int) var max_ap = 4
var current_ap = 0

export(int) var max_health = 10
var current_health = 10

export(int) var attack_stat = 5
export(int) var defense_stat = 3

export(Texture) var unit_picture # For UI portraits
export(UnitClass) var unit_class = UnitClass.WARRIOR

# --- Equipment Slots (Placeholder for later) ---
export(Resource) var weapon_slot = null

# --- Patterns ---
# Drag your .tres files (e.g., "move_pattern_A.tres") here in the Inspector
export(Resource) var movement_pattern
export(Resource) var attack_pattern

# --- Internal Vars ---
var grid_pos = Vector2(0, 0) setget set_grid_pos
var tilemap_node = null

func _ready():
	current_ap = max_ap
	current_health = max_health
	pass

# This "setter" function automatically updates the unit's
# *pixel* position whenever its *grid* position is changed.
func set_grid_pos(new_pos):
	grid_pos = new_pos
	if tilemap_node:
		# Get the top-most corner of the cell
		var cell_world_pos = tilemap_node.map_to_world(grid_pos)
		
		# Calculate the visual *center* of the tile
		var cell_visual_center = cell_world_pos + Vector2(0, tilemap_node.cell_size.y / 2)
		
		# We offset the position by (-1, -1) pixels from the center.
		var safe_position = cell_visual_center - Vector2(1, 1)
		
		# Set the unit's pixel position
		position = safe_position

# --- Public Functions ---

func reset_ap():
	current_ap = max_ap

# Returns an array of *absolute* grid positions
func get_valid_move_cells():
	var cells = []
	if movement_pattern:
		for offset in movement_pattern.cells:
			cells.append(grid_pos + offset)
	# The *actual* validation (for banned tiles) will happen in Main.gd
	return cells

# Returns an array of *absolute* grid positions
func get_valid_attack_cells():
	var cells = []
	if attack_pattern:
		for offset in attack_pattern.cells:
			cells.append(grid_pos + offset)
	return cells

func move_to_cell(target_cell_pos):
	# This assumes 1 AP per move. You can make this cost a parameter.
	if current_ap <= 0:
		print("Not enough AP to move!")
		return current_ap # Return current AP

	current_ap -= 1
	set_grid_pos(target_cell_pos)
	print("Unit moved. AP remaining: ", current_ap)
	return current_ap # Return new AP
	
func attack_cell(target_cell_pos):
	# This assumes 1 AP per attack.
	if current_ap <= 0:
		print("Not enough AP to attack!")
		return current_ap # Return current AP

	current_ap -= 1
	print("Attacked cell ", target_cell_pos, "! AP remaining: ", current_ap)
	# --- Add your attack/damage logic here ---
	
	return current_ap # Return new AP
