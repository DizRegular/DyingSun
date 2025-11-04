extends Node2D

# --- TileMaps ---
onready var tilemap = $Ground
onready var highlight_map = $HighlightMap 
onready var highlight_attack_map = $HighlightAttackMap
onready var banned_map = $BannedMap
onready var deployment_map = $DeploymentMap

# --- UI Nodes ---
onready var combat_ui = $UI/CombatUI
onready var deployment_ui = $UI/DeploymentUI
onready var unit_party_container = $UI/DeploymentUI/UnitPartyUI
onready var ap_label = $UI/CombatUI/APLabel # NEW: AP Label

# --- Unit Scenes ---
# In the Inspector, drag your Unit.tscn (and others) into this array
export(Array, PackedScene) var player_party_scenes

# --- State ---
var selected_unit: Unit = null
enum ActionState { NONE, MOVING, ATTACKING, DEPLOYING }
var current_action_state = ActionState.NONE

var pending_unit_scene: PackedScene = null

# --- Clickable Cells ---
var valid_move_cells = []
var valid_attack_cells = []
var valid_deployment_cells = []


func _ready():
	# We start with empty maps and let the player deploy units
	GameManager.set_player_party(player_party_scenes)
	GameManager.start_game([], []) 
	
	setup_deployment_ui()
	show_deployment_zone()
	
	# Connect UI buttons
	$UI/CombatUI/EndTurnButton.connect("pressed", self, "_on_EndTurnButton_pressed")
	$UI/CombatUI/MoveButton.connect("pressed", self, "_on_MoveButton_pressed")
	$UI/CombatUI/AttackButton.connect("pressed", self, "_on_AttackButton_pressed")
	$UI/DeploymentUI/EndDeploymentButton.connect("pressed", self, "_on_EndDeploymentButton_pressed")

func _process(delta):
	# This function controls which UI is visible
	if GameManager.current_state == GameManager.TurnState.DEPLOYMENT:
		combat_ui.hide()
		deployment_ui.show()
	else:
		combat_ui.show()
		deployment_ui.hide()
		# Hide combat buttons and AP if no unit is selected
		if !selected_unit:
			$UI/CombatUI/MoveButton.hide()
			$UI/CombatUI/AttackButton.hide()
			ap_label.hide()


func _unhandled_input(event):
	# --- State-specific Input Handling ---
	match GameManager.current_state:
		GameManager.TurnState.DEPLOYMENT:
			handle_deployment_input(event)
		GameManager.TurnState.PLAYER_TURN:
			handle_combat_input(event)

# --- Deployment Phase Logic ---

func handle_deployment_input(event):
	# Right-click cancels deployment
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT:
		cancel_action()
		return

	# Left-click to deploy
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var click_pos = get_global_mouse_position()
		var grid_pos = tilemap.world_to_map(click_pos)

		if current_action_state == ActionState.DEPLOYING:
			if grid_pos in valid_deployment_cells:
				# Deploy the unit!
				var new_unit = pending_unit_scene.instance()
				add_child(new_unit) # Add to the Main scene
				new_unit.tilemap_node = tilemap
				new_unit.set_grid_pos(grid_pos)
				
				# Add to GameManager and remove from party list
				GameManager.player_units.append(new_unit)
				GameManager.player_party_scenes.erase(pending_unit_scene)
				
				# Reset state
				cancel_action()
				setup_deployment_ui() # Rebuilds UI without the deployed unit
			else:
				# Clicked invalid spot
				cancel_action()
		else:
			# Not deploying, just clicked on the map.
			# You could add logic to "pick up" a unit here,
			# but for now, we'll just cancel.
			cancel_action()

func setup_deployment_ui():
	# Clear old buttons
	for child in unit_party_container.get_children():
		child.queue_free()
	
	# Create new buttons for available units
	for scene in GameManager.player_party_scenes:
		var btn = Button.new()
		# We need a way to get the unit's name from the scene
		# For now, just use the scene file name
		btn.text = scene.resource_path.get_file().replace(".tscn", "")
		btn.connect("pressed", self, "_on_deploy_unit_pressed", [scene])
		unit_party_container.add_child(btn)

func _on_deploy_unit_pressed(scene: PackedScene):
	# Called when a unit button in the party UI is clicked
	current_action_state = ActionState.DEPLOYING
	pending_unit_scene = scene
	show_deployment_zone()

func _on_EndDeploymentButton_pressed():
	hide_all_ranges()
	GameManager.finish_deployment()
	# Combat UI will appear on the next _process frame


# --- Combat Phase Logic ---

func handle_combat_input(event):
	if GameManager.current_state != GameManager.TurnState.PLAYER_TURN:
		return

	# Right-click always cancels the current action
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT:
		cancel_action()
		return

	# Left-click handles selection and actions
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var click_pos = get_global_mouse_position()
		var grid_pos = tilemap.world_to_map(click_pos)

		match current_action_state:
			ActionState.NONE:
				var unit_at_click = get_unit_at(grid_pos)
				if unit_at_click and unit_at_click in GameManager.player_units:
					select_unit(unit_at_click)
				else:
					deselect_unit()
			
			ActionState.MOVING:
				if grid_pos in valid_move_cells:
					# Unit.gd now returns the new AP
					var new_ap = selected_unit.move_to_cell(grid_pos)
					ap_label.text = "AP: " + str(new_ap) + " / " + str(selected_unit.max_ap)
					cancel_action() 
					select_unit(selected_unit)
				else:
					cancel_action()
			
			ActionState.ATTACKING:
				if grid_pos in valid_attack_cells:
					# Unit.gd now returns the new AP
					var new_ap = selected_unit.attack_cell(grid_pos)
					ap_label.text = "AP: " + str(new_ap) + " / " + str(selected_unit.max_ap)
					cancel_action()
					select_unit(selected_unit)
				else:
					cancel_action()

# --- UI Functions (Combat) ---

func select_unit(unit: Unit):
	selected_unit = unit
	current_action_state = ActionState.NONE
	hide_all_ranges()
	print("Selected unit with ", unit.current_ap, " AP.")
	
	# Update and show AP Label
	ap_label.text = "AP: " + str(unit.current_ap) + " / " + str(unit.max_ap)
	ap_label.show()
	
	# Show UI buttons if unit has AP
	if unit.current_ap > 0:
		$UI/CombatUI/MoveButton.show()
		$UI/CombatUI/AttackButton.show()
	else:
		$UI/CombatUI/MoveButton.hide()
		$UI/CombatUI/AttackButton.hide()

func deselect_unit():
	selected_unit = null
	# THIS IS THE CORRECTED LINE:
	current_action_state = ActionState.NONE
	hide_all_ranges()
	$UI/CombatUI/MoveButton.hide()
	$UI/CombatUI/AttackButton.hide()
	ap_label.text = ""
	ap_label.hide()

func cancel_action():
	# This is now a general-purpose reset
	hide_all_ranges()
	current_action_state = ActionState.NONE
	pending_unit_scene = null
	
	if GameManager.current_state == GameManager.TurnState.DEPLOYMENT:
		show_deployment_zone()
	elif selected_unit:
		select_unit(selected_unit) # Reshows buttons and AP
	else:
		deselect_unit() # Hides buttons and AP

# --- Button Handlers (Combat) ---

func _on_MoveButton_pressed():
	if selected_unit:
		current_action_state = ActionState.MOVING
		show_movement_range(selected_unit)

func _on_AttackButton_pressed():
	if selected_unit:
		current_action_state = ActionState.ATTACKING
		show_attack_range(selected_unit)

func _on_EndTurnButton_pressed():
	deselect_unit()
	GameManager.end_turn()

# --- Helper Functions (NEW & UPDATED) ---

func is_cell_walkable(grid_pos: Vector2) -> bool:
	# A cell is walkable if it's on the main map AND NOT on the banned map
	return bool(tilemap.get_cellv(grid_pos) != TileMap.INVALID_CELL) and \
		   bool(banned_map.get_cellv(grid_pos) == TileMap.INVALID_CELL)

func get_unit_at(grid_position):
	for unit in GameManager.player_units:
		if unit.grid_pos == grid_position:
			return unit
	for unit in GameManager.enemy_units:
		if unit.grid_pos == grid_position:
			return unit
	return null

# --- Range & Highlight Functions (NEW & UPDATED) ---

func show_deployment_zone():
	hide_all_ranges()
	valid_deployment_cells.clear()
	
	# Get all tiles in the DeploymentMap
	var cells = deployment_map.get_used_cells()
	for cell in cells:
		# A tile is valid if it's walkable AND not occupied
		if is_cell_walkable(cell) and get_unit_at(cell) == null:
			valid_deployment_cells.append(cell)
			highlight_map.set_cellv(cell, 0) # Highlight blue

func show_movement_range(unit: Unit):
	hide_all_ranges()
	valid_move_cells.clear()
	var potential_cells = unit.get_valid_move_cells()
	
	for cell in potential_cells:
		# A move is valid if it's walkable AND not occupied
		if is_cell_walkable(cell) and get_unit_at(cell) == null:
			valid_move_cells.append(cell)
			highlight_map.set_cellv(cell, 0) # Highlight blue

func show_attack_range(unit: Unit):
	hide_all_ranges()
	valid_attack_cells = unit.get_valid_attack_cells()
	
	# Set highlight color based on unit class (using corrected classes)
	var tile_id = 0 # Default tile (e.g., red)
	match unit.unit_class:
		Unit.UnitClass.WARRIOR:
			tile_id = 0 # Assumes tile 0 in your TileSet is red
		Unit.UnitClass.ARCHER:
			tile_id = 1 # Assumes tile 1 is green/yellow
		Unit.UnitClass.WIZARD:
			tile_id = 2 # Assumes tile 2 is blue/purple
		Unit.UnitClass.SUPPORTER:
			tile_id = 3 # Assumes tile 3 is white/cyan
	
	# (You need to add these tiles to your HighlightAttackMap's TileSet)
	
	for cell in valid_attack_cells:
		highlight_attack_map.set_cellv(cell, tile_id) # Use the new tile_id

func hide_all_ranges():
	highlight_map.clear()
	highlight_attack_map.clear()
	valid_move_cells.clear()
	valid_attack_cells.clear()
	valid_deployment_cells.clear()
