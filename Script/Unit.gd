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
var equipped_weapon: Weapon = null

# --- Patterns ---
export(Resource) var movement_pattern

# --- Internal Vars ---
var grid_pos = Vector2(0, 0) setget set_grid_pos
var tilemap_node = null
var is_enemy = false # NEW: Flag to identify faction

# --- NEW: Signal for UI ---
signal health_changed

func _ready():
	current_ap = max_ap
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

func equip_weapon(weapon: Weapon):
	if weapon and weapon.weapon_class == unit_class:
		equipped_weapon = weapon
		unit_name = equipped_weapon.weapon_name + " " + unit_name
		current_health = get_modified_max_health()
	else:
		print("Weapon incompatible or null!")
		current_health = get_modified_max_health()

# --- Stat Getters (NEW) ---
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

func get_valid_attack_cells():
	var cells = []
	if equipped_weapon and equipped_weapon.attack_pattern:
		for offset in equipped_weapon.attack_pattern.cells:
			cells.append(grid_pos + offset)
	else:
		print("No weapon or attack pattern!")
	return cells

# --- NEW: Skill Cell Getter ---
func get_valid_skill_cells():
	var cells = []
	if equipped_weapon and equipped_weapon.unique_skill and equipped_weapon.unique_skill.skill_pattern:
		for offset in equipped_weapon.unique_skill.skill_pattern.cells:
			cells.append(grid_pos + offset)
	return cells
	
# --- Action Functions (UPDATED) ---

func move_to_cell(target_cell_pos):
	if current_ap <= 0:
		print("Not enough AP to move!")
		return current_ap 

	current_ap -= 1
	set_grid_pos(target_cell_pos)
	print("Unit moved. AP remaining: ", current_ap)
	return current_ap
	
# UPDATED: Now takes main_node and deals damage
func attack_cell(target_cell_pos, main_node: Node2D):
	if current_ap <= 0:
		print("Not enough AP to attack!")
		return current_ap

	if !equipped_weapon:
		print("No weapon equipped, can't attack!")
		return current_ap

	current_ap -= 1
	print("Attacked cell ", target_cell_pos, "! AP remaining: ", current_ap)
	
	# --- NEW: Damage Logic ---
	var target = main_node.get_unit_at(target_cell_pos)
	if target:
		# Simple damage formula
		var damage = get_modified_attack() - target.get_modified_defense()
		damage = max(1, damage) # Always do at least 1 damage
		
		print(unit_name, " deals ", damage, " damage to ", target.unit_name)
		target.take_damage(damage)
	else:
		print("...but missed!")
	# --- End Damage Logic ---
	
	return current_ap

# NEW: Skill execution
func use_skill(target_cell_pos, main_node: Node2D):
	if !equipped_weapon or !equipped_weapon.unique_skill:
		print("No skill to use!")
		return current_ap
		
	var skill = equipped_weapon.unique_skill
	
	if current_ap < skill.ap_cost:
		print("Not enough AP for skill!")
		return current_ap

	current_ap -= skill.ap_cost
	print("Used skill '", skill.skill_name, "' on ", target_cell_pos)
	
	# Delegate the skill's logic to the skill resource itself
	skill.execute(self, target_cell_pos, main_node)
	
	return current_ap

# --- NEW: Health & Death ---

func take_damage(amount: int):
	current_health -= amount
	current_health = max(0, current_health) # Clamp at 0
	
	print(unit_name, " takes ", amount, " damage. ", current_health, "/", get_modified_max_health(), " HP left.")
	
	# Emit signal for UI to update
	emit_signal("health_changed")
	
	if current_health <= 0:
		die()

func die():
	print(unit_name, " has been defeated!")
	
	# Remove self from the correct list in GameManager
	if is_enemy:
		GameManager.enemy_units.erase(self)
	else:
		GameManager.player_units.erase(self)
	
	# Check for win/lose
	GameManager.check_game_over()
	
	# Remove from the scene
	queue_free()
