extends Node
class_name EnemyAI

# This script should be added as a child node to your enemy Unit scene (e.g., Orc.tscn)
# It will automatically find its parent 'Unit'
onready var unit = get_parent()

# Signal to the GameManager that this unit's turn is over
signal turn_finished

# --- Public AI Function ---

# This is called by GameManager
# We make it a 'func' to use 'yield' for dramatic pauses
func execute_turn(main_node: Node2D, player_units: Array):
	# If no AP, end turn immediately
	if unit.current_ap <= 0:
		emit_signal("turn_finished")
		return

	# Simple AI:
	# 1. Find the closest player
	# 2. Check if in attack range. If yes, attack.
	# 3. If no, move closer.
	# 4. After moving, check again if in attack range. If yes, attack.
	
	# Small delay so the player can see the AI thinking
	yield(get_tree().create_timer(0.5), "timeout")

	var closest_player = find_closest_player(player_units)
	if !closest_player:
		print(unit.unit_name, " has no one to attack.")
		emit_signal("turn_finished")
		return
	
	# --- Action 1: Attack or Move ---
	var target_cell = can_attack_target(closest_player, main_node)
	
	if target_cell != Vector2.INF:
		# Can attack!
		print(unit.unit_name, " attacks!")
		unit.attack_cell(target_cell, main_node)
		unit.current_ap += 1 # Compensate for AP cost of attack
		
	else:
		# Can't attack, try to move
		if unit.current_ap > 0:
			print(unit.unit_name, " moves.")
			move_towards_target(closest_player, main_node)
		
	# --- Action 2: Attack after moving ---
	if unit.current_ap > 0:
		# Small delay after moving
		yield(get_tree().create_timer(0.5), "timeout")
		
		target_cell = can_attack_target(closest_player, main_node)
		if target_cell != Vector2.INF:
			# Can attack now!
			print(unit.unit_name, " attacks after moving!")
			unit.attack_cell(target_cell, main_node)
		else:
			print(unit.unit_name, " ends turn (no attack).")
	
	# --- End Turn ---
	print(unit.unit_name, " finishes its turn.")
	emit_signal("turn_finished")


# --- AI Helper Functions ---

func find_closest_player(player_units: Array):
	var closest_player = null
	var min_dist = 9999
	
	for player_unit in player_units:
		var dist = unit.grid_pos.distance_to(player_unit.grid_pos)
		if dist < min_dist:
			min_dist = dist
			closest_player = player_unit
			
	return closest_player

# Checks if the target is in attack range.
# Returns the target's cell if true, or Vector2.INF if false.
func can_attack_target(target_unit: Unit, main_node: Node2D) -> Vector2:
	var attack_cells = unit.get_valid_attack_cells()
	if target_unit.grid_pos in attack_cells:
		
		# Check for line of sight (simple version: no obstacles)
		# You can expand this later
		return target_unit.grid_pos
		
	return Vector2.INF # Use INF as a "not found" value

# Finds a valid move cell that is closer to the target
func move_towards_target(target_unit: Unit, main_node: Node2D):
	var valid_moves = unit.get_valid_move_cells()
	var best_move = unit.grid_pos
	var min_dist = unit.grid_pos.distance_to(target_unit.grid_pos)
	
	var cells_to_check = []
	for cell in valid_moves:
		# Check if cell is walkable AND empty
		if main_node.is_cell_walkable(cell) and main_node.get_unit_at(cell) == null:
			cells_to_check.append(cell)
	
	if cells_to_check.empty():
		print(unit.unit_name, " is blocked!")
		return # No valid moves
		
	# Find the move that gets closest
	for move_cell in cells_to_check:
		var dist = move_cell.distance_to(target_unit.grid_pos)
		if dist < min_dist:
			min_dist = dist
			best_move = move_cell
	
	if best_move != unit.grid_pos:
		unit.move_to_cell(best_move)
	else:
		print(unit.unit_name, " stays put.")
