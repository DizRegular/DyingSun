extends KinematicBody2D
class_name Unit

# Enum for unit class. This will be a dropdown in the Inspector.
enum UnitClass { WARRIOR, ARCHER, WIZARD, SUPPORT }

# --- Unit Stats (Base Stats) ---
export(String) var unit_name = "Unit"
export(int) var max_ap = 4
var current_ap = 0

export(int) var max_health = 10
var current_health = 10

export(int) var attack_stat = 5
export(int) var defense_stat = 3

export(Texture) var unit_picture # For UI portraits
export(UnitClass) var unit_class = UnitClass.WARRIOR

# --- Equipment ---
# This is set *after* instancing, from the PartyMember resource
var equipped_weapon: Weapon = null

# --- Patterns ---
# Movement is still controlled by the unit
export(Resource) var movement_pattern
# ATTACK PATTERN AND WEAPON_SLOT ARE NOW REMOVED FROM HERE

# --- Internal Vars ---
var grid_pos = Vector2(0, 0) setget set_grid_pos
var tilemap_node = null

func _ready():
	current_ap = max_ap
	# Health is now set *after* equipment is applied (in equip_weapon)
	# But we set it here as a fallback.
	current_health = get_modified_max_health()
	pass

func set_grid_pos(new_pos):
	grid_pos = new_pos
	if tilemap_node:
		var cell_world_pos = tilemap_node.map_to_world(grid_pos)
		var cell_visual_center = cell_world_pos + Vector2(0, tilemap_node.cell_size.y / 2)
		var safe_position = cell_visual_center - Vector2(1, 1)
		position = safe_position

# --- Public Functions ---

# NEW: Called by Main.gd when the unit is deployed
func equip_weapon(weapon: Weapon):
	if weapon and weapon.weapon_class == unit_class:
		equipped_weapon = weapon
		# Apply stats from weapon
		unit_name = equipped_weapon.weapon_name + " " + unit_name
		# Set current health based on new max health
		current_health = get_modified_max_health()
	else:
		print("Weapon incompatible or null!")
		current_health = get_modified_max_health() # Set base health

# --- Stat Getters (NEW) ---
# These functions calculate stats including weapon buffs
func get_modified_max_health() -> int:
	if equipped_weapon:
		return int(max_health * equipped_weapon.hp_multiplier)
	return max_health

func get_modified_attack() -> int:
	if equipped_weapon:
		return int(attack_stat * equipped_weapon.atk_multiplier)
	return attack_stat

func get_modified_defense() -> int:
	if equipped_weapon:
		return int(defense_stat * equipped_weapon.def_multiplier)
	return defense_stat

# --- (Other functions like reset_ap are unchanged) ---
func reset_ap():
	current_ap = max_ap

func get_valid_move_cells():
	var cells = []
	if movement_pattern:
		for offset in movement_pattern.cells:
			cells.append(grid_pos + offset)
	return cells

# UPDATED: Now gets pattern from the *weapon*
func get_valid_attack_cells():
	var cells = []
	if equipped_weapon and equipped_weapon.attack_pattern:
		for offset in equipped_weapon.attack_pattern.cells:
			cells.append(grid_pos + offset)
	else:
		print("No weapon or attack pattern!")
	return cells

func move_to_cell(target_cell_pos):
	if current_ap <= 0:
		print("Not enough AP to move!")
		return current_ap 

	current_ap -= 1
	set_grid_pos(target_cell_pos)
	print("Unit moved. AP remaining: ", current_ap)
	return current_ap
	
func attack_cell(target_cell_pos):
	if current_ap <= 0:
		print("Not enough AP to attack!")
		return current_ap

	if !equipped_weapon:
		print("No weapon equipped, can't attack!")
		return current_ap

	current_ap -= 1
	print("Attacked cell ", target_cell_pos, "! AP remaining: ", current_ap)
	# --- Add your attack/damage logic here ---
	
	return current_ap
