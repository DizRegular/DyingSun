extends Node

enum TurnState { DEPLOYMENT, PLAYER_TURN, ENEMY_TURN }
var current_state = TurnState.DEPLOYMENT

# --- Deployed Units (on map) ---
var player_units = [] 
var enemy_units = []

# --- Rosters (not on map) ---
var player_party = []
var weapon_inventory = []

# --- NEW: References for AI ---
var main_node = null # Set by Main.gd
var current_enemy_index = 0

func _ready():
	pass

func set_player_party(party: Array):
	for member in party:
		player_party.append(member.duplicate())

func set_weapon_inventory(weapons: Array):
	for weapon in weapons:
		weapon_inventory.append(weapon.duplicate())

func start_game(p_units, e_units):
	player_units = p_units
	enemy_units = e_units # This will be populated by Main.gd
	current_state = TurnState.DEPLOYMENT
	print("Deployment phase starts!")

func finish_deployment():
	if current_state == TurnState.DEPLOYMENT:
		start_player_turn()

func start_player_turn():
	print("Player turn starts!")
	current_state = TurnState.PLAYER_TURN
	for unit in player_units:
		unit.reset_ap()

func start_enemy_turn():
	print("--- ENEMY TURN STARTS ---")
	current_state = TurnState.ENEMY_TURN
	
	# Reset AP for all enemies
	for unit in enemy_units:
		unit.reset_ap()
	
	# Start the AI turn for the first enemy
	current_enemy_index = 0
	run_next_enemy_ai()

# --- NEW: AI Turn Management ---

func run_next_enemy_ai():
	# Check if all enemies have moved
	if current_enemy_index >= enemy_units.size():
		print("--- ENEMY TURN ENDS ---")
		end_turn() # All enemies are done, switch to player
		return

	# Get the next enemy
	var unit = enemy_units[current_enemy_index]
	
	# Find its AI script
	var ai = unit.get_node_or_null("EnemyAI")
	
	if ai:
		# Connect to its 'turn_finished' signal
		ai.connect("turn_finished", self, "_on_enemy_ai_finished", [], CONNECT_ONESHOT)
		# Tell it to execute its turn
		ai.execute_turn(main_node, player_units)
	else:
		# This enemy has no AI, skip it
		print("WARNING: Enemy ", unit.unit_name, " has no EnemyAI node!")
		_on_enemy_ai_finished()

func _on_enemy_ai_finished():
	# This is called when an enemy's AI.turn_finished signal is emitted
	current_enemy_index += 1
	run_next_enemy_ai() # Run the next enemy's turn

# ---

func end_turn():
	if current_state == TurnState.PLAYER_TURN:
		start_enemy_turn()
	else:
		start_player_turn()

# --- NEW: Win/Lose Condition Check ---

func check_game_over():
	if current_state == TurnState.DEPLOYMENT:
		return # Don't check during setup

	if player_units.size() == 0:
		print("--- DEFEAT! ---")
		get_tree().reload_current_scene()
	
	if enemy_units.size() == 0:
		print("--- VICTORY! ---")
		get_tree().reload_current_scene()
