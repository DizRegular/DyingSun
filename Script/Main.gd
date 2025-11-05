extends Node2D

# --- TileMaps ---
onready var tilemap = $Ground
onready var highlight_map = $HighlightMap 
onready var highlight_attack_map = $HighlightAttackMap
onready var banned_map = $BannedMap
onready var deployment_map = $DeploymentMap
onready var unit_container = $UnitContainer # NEW: For YSort

# --- UI Nodes ---
onready var combat_ui = $UI/CombatUI
onready var deployment_ui = $UI/DeploymentUI
onready var unit_party_container = $UI/DeploymentUI/UnitPartyUI
onready var weapon_inventory_container = $UI/DeploymentUI/WeaponInventoryUI 
onready var ap_label = $UI/CombatUI/APLabel
onready var skill_button = $UI/CombatUI/SkillButton # NEW: For unique skills

# --- Stats Panel UI Nodes (with 'Content/' path) ---
onready var stats_panel = $UI/CombatUI/StatsPanel
onready var unit_portrait = $UI/CombatUI/StatsPanel/Content/UnitPortrait
onready var unit_name_label = $UI/CombatUI/StatsPanel/Content/StatsVBox/UnitNameLabel
onready var unit_hp_label = $UI/CombatUI/StatsPanel/Content/StatsVBox/UnitHPLabel
onready var unit_atk_label = $UI/CombatUI/StatsPanel/Content/StatsVBox/UnitStatsHBox/UnitATKLabel
onready var unit_def_label = $UI/CombatUI/StatsPanel/Content/StatsVBox/UnitStatsHBox/UnitDEFLabel

# --- Exported Resources ---
export(Array, Resource) var player_party # Drag PartyMember.tres files here
export(Array, Resource) var initial_weapon_inventory # Drag Weapon.tres files here

# --- State ---
var selected_unit: Unit = null
enum ActionState { NONE, MOVING, ATTACKING, DEPLOYING, SKILL } # NEW: Added SKILL
var current_action_state = ActionState.NONE

var pending_party_member: PartyMember = null 

# --- Clickable Cells ---
var valid_move_cells = []
var valid_attack_cells = []
var valid_deployment_cells = []
var valid_skill_cells = [] # NEW: For skills

# --- Color definitions ---
const CLASS_COLORS = {
	Unit.UnitClass.WARRIOR: Color(1.0, 0.4, 0.4), # Red
	Unit.UnitClass.ARCHER: Color(1.0, 1.0, 0.4), # Yellow
	Unit.UnitClass.WIZARD: Color(0.8, 0.4, 1.0), # Purple
	Unit.UnitClass.SUPPORT: Color(0.4, 1.0, 0.4) # Green
}

func _ready():
	# Pass resources to the GameManager
	GameManager.set_player_party(player_party)
	GameManager.set_weapon_inventory(initial_weapon_inventory)
	
	GameManager.start_game([], []) 
	
	# Set up the Deployment UI
	setup_deployment_ui()
	setup_weapon_inventory_ui()
	show_deployment_zone()
	
	# Set up the link for the drop zone
	unit_party_container.main_script = self
	
	stats_panel.hide()
	
	# Connect UI buttons
	$UI/CombatUI/EndTurnButton.connect("pressed", self, "_on_EndTurnButton_pressed")
	$UI/CombatUI/MoveButton.connect("pressed", self, "_on_MoveButton_pressed")
	$UI/CombatUI/AttackButton.connect("pressed", self, "_on_AttackButton_pressed")
	$UI/CombatUI/.connect("pressed", self, "_on_SkillButton_pressed") # NEW
	$UI/DeploymentUI/EndDeploymentButton.connect("pressed", self, "_on_EndDeploymentButton_pressed")

func _process(delta):
	# This function controls which UI is visible
	if GameManager.current_state == GameManager.TurnState.DEPLOYMENT:
		combat_ui.hide()
		deployment_ui.show()
	else:
		combat_ui.show()
		deployment_ui.hide()
		# Hide combat buttons, AP, and Stats if no unit is selected
		if !selected_unit:
			$UI/CombatUI/MoveButton.hide()
			$UI/CombatUI/AttackButton.hide()
			skill_button.hide() # NEW
			ap_label.hide()
			stats_panel.hide()


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
				var new_unit = pending_party_member.unit_scene.instance()
				
				# Add to the YSort node
				unit_container.add_child(new_unit) # YSORT FIX
				
				new_unit.tilemap_node = tilemap
				
				# Equip weapon *before* setting position
				if pending_party_member.equipped_weapon:
					new_unit.equip_weapon(pending_party_member.equipped_weapon)
				else:
					new_unit.equip_weapon(null)
				
				new_unit.set_grid_pos(grid_pos)
				
				# Add to GameManager and remove from party list
				GameManager.player_units.append(new_unit)
				GameManager.player_party.erase(pending_party_member)
				
				# Reset state
				cancel_action()
				setup_deployment_ui() # Rebuilds UI
			else:
				# Clicked invalid spot
				cancel_action()
		else:
			cancel_action()

func setup_deployment_ui():
	# Clear old buttons
	for child in unit_party_container.get_children():
		child.queue_free()
	
	# Create new buttons for available units
	for member in GameManager.player_party:
		var btn = Button.new()
		var text = member.unit_name
		if member.equipped_weapon:
			text += " (" + member.equipped_weapon.weapon_name + ")"
		else:
			text += " (No Weapon)"
		btn.text = text
		
		# Set button color based on class
		btn.set_modulate(CLASS_COLORS[member.unit_class])
		
		# Store the party member data *on the button*
		btn.set_meta("party_member", member)
		
		# THE FIX: Make buttons transparent to drag events
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		btn.connect("pressed", self, "_on_deploy_unit_pressed", [member])
		unit_party_container.add_child(btn)

func setup_weapon_inventory_ui():
	# Clear old buttons
	for child in weapon_inventory_container.get_children():
		child.queue_free()
	
	# Create new buttons for available weapons
	for weapon in GameManager.weapon_inventory:
		# Use our new button script
		var btn = WeaponDragButton.new() 
		btn.text = weapon.weapon_name
		# Give the button the weapon data
		btn.weapon = weapon 
		# Set button color based on class
		btn.set_modulate(CLASS_COLORS[weapon.weapon_class])
		
		weapon_inventory_container.add_child(btn)

# --- Drag and Drop Functions ---

# Called by PartyContainer.gd
func can_drop_data_on_party(position, data, from_node) -> bool:
	if data.type != "weapon":
		return false
	
	# Find which button we're hovering over
	var local_pos = from_node.get_local_mouse_position()
	for child in from_node.get_children():
		if child.get_rect().has_point(local_pos):
			# Found the button!
			return true
	
	# Not over any button
	return false

# Called by PartyContainer.gd
func drop_data_on_party(position, data, from_node):
	# Find the button we dropped on
	var local_pos = from_node.get_local_mouse_position()
	var target_button = null
	
	for child in from_node.get_children():
		if child.get_rect().has_point(local_pos):
			target_button = child
			break # Found it

	if not target_button:
		return # Missed, dropped on empty space
	
	var weapon = data.weapon
	var party_member = target_button.get_meta("party_member") 
	
	# Check for class compatibility
	if weapon.weapon_class != party_member.unit_class:
		print("Incompatible weapon! Unit: ", party_member.unit_class, " Weapon: ", weapon.weapon_class)
		return

	# Handle equipping and swapping
	var old_weapon = party_member.equipped_weapon
	
	party_member.equipped_weapon = weapon
	GameManager.weapon_inventory.erase(weapon)
	
	if old_weapon:
		GameManager.weapon_inventory.append(old_weapon)
		
	print("Equipped ", weapon.weapon_name, " to ", party_member.unit_name)
	
	# Rebuild both UIs
	setup_deployment_ui()
	setup_weapon_inventory_ui()

# --- (End of Drag/Drop) ---

func _on_deploy_unit_pressed(member: PartyMember):
	# Called when a unit button in the party UI is clicked
	if member.equipped_weapon == null:
		print(member.unit_name, " has no weapon equipped!")
		return
		
	current_action_state = ActionState.DEPLOYING
	pending_party_member = member
	show_deployment_zone()

func _on_EndDeploymentButton_pressed():
	if GameManager.player_party.size() > 0:
		print("You still have units to deploy!")
		return
		
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
					var new_ap = selected_unit.move_to_cell(grid_pos)
					ap_label.text = "AP: " + str(new_ap) + " / " + str(selected_unit.max_ap)
					cancel_action() 
					select_unit(selected_unit)
				else:
					cancel_action()
			
			ActionState.ATTACKING:
				if grid_pos in valid_attack_cells:
					var new_ap = selected_unit.attack_cell(grid_pos)
					ap_label.text = "AP: " + str(new_ap) + " / " + str(selected_unit.max_ap)
					cancel_action()
					select_unit(selected_unit)
				else:
					cancel_action()
			
			ActionState.SKILL: # NEW
				if grid_pos in valid_skill_cells:
					# Pass 'self' as the 'main_node'
					var new_ap = selected_unit.use_skill(grid_pos, self) 
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
	
	# --- UPDATE STATS PANEL ---
	stats_panel.show()
	unit_portrait.texture = unit.unit_picture
	unit_name_label.text = unit.unit_name
	# Use getter functions for stats
	unit_hp_label.text = "HP: " + str(unit.current_health) + " / " + str(unit.get_modified_max_health())
	unit_atk_label.text = "ATK: " + str(unit.get_modified_attack())
	unit_def_label.text = "DEF: " + str(unit.get_modified_defense())
	
	# Update and show AP Label
	ap_label.text = "AP: " + str(unit.current_ap) + " / " + str(unit.max_ap)
	ap_label.show()
	
	# Show UI buttons if unit has AP
	if unit.current_ap > 0:
		$UI/CombatUI/MoveButton.show()
		# Only show Attack if weapon is equipped
		if unit.equipped_weapon:
			$UI/CombatUI/AttackButton.show()
		# Only show Skill if weapon has one AND unit has AP
		if unit.equipped_weapon and unit.equipped_weapon.unique_skill and unit.current_ap >= unit.equipped_weapon.unique_skill.ap_cost:
			skill_button.text = unit.equipped_weapon.unique_skill.skill_name
			skill_button.show()
		else:
			skill_button.hide()
	else:
		$UI/CombatUI/MoveButton.hide()
		$UI/CombatUI/AttackButton.hide()
		skill_button.hide()

func deselect_unit():
	selected_unit = null
	current_action_state = ActionState.NONE
	hide_all_ranges()
	
	# Hide all combat UI
	$UI/CombatUI/MoveButton.hide()
	$UI/CombatUI/AttackButton.hide()
	skill_button.hide()
	ap_label.text = ""
	ap_label.hide()
	stats_panel.hide() # Hide stats panel

func cancel_action():
	# This is now a general-purpose reset
	hide_all_ranges()
	current_action_state = ActionState.NONE
	pending_party_member = null
	
	if GameManager.current_state == GameManager.TurnState.DEPLOYMENT:
		show_deployment_zone()
		# Rebuild UI in case a drag was cancelled
		setup_deployment_ui()
		setup_weapon_inventory_ui()
	elif selected_unit:
		select_unit(selected_unit) # Reshows buttons, AP, and Stats
	else:
		deselect_unit() # Hides buttons, AP, and Stats

# --- Button Handlers (Combat) ---

func _on_MoveButton_pressed():
	if selected_unit:
		current_action_state = ActionState.MOVING
		show_movement_range(selected_unit)

func _on_AttackButton_pressed():
	if selected_unit and selected_unit.equipped_weapon:
		current_action_state = ActionState.ATTACKING
		show_attack_range(selected_unit)
	else:
		print("No weapon equipped!")

func _on_SkillButton_pressed(): # NEW
	if selected_unit and selected_unit.equipped_weapon and selected_unit.equipped_weapon.unique_skill:
		current_action_state = ActionState.SKILL
		show_skill_range(selected_unit)
	else:
		print("No skill to use!")

func _on_EndTurnButton_pressed():
	deselect_unit()
	GameManager.end_turn()

# --- Helper Functions (NEW & UPDATED) ---

func is_cell_walkable(grid_pos: Vector2) -> bool:
	# A cell is walkable if it's on the main map AND NOT on the banned map
	return bool(tilemap.get_cellv(grid_pos) != TileMap.INVALID_CELL) and \
		   bool(banned_map.get_cellv(grid_pos) == TileMap.INVALID_CELL)

func get_unit_at(grid_position):
	# Check YSort container for units
	for unit in unit_container.get_children():
		# Make sure we're only checking valid Unit nodes
		if unit is Unit and unit.grid_pos == grid_position:
			# Check if it's in a known list (player or enemy)
			if unit in GameManager.player_units or unit in GameManager.enemy_units:
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
	
	if !unit.equipped_weapon:
		return
		
	valid_attack_cells = unit.get_valid_attack_cells()
	
	# Set highlight color based on unit class
	var tile_id = 0
	match unit.unit_class:
		Unit.UnitClass.WARRIOR:
			tile_id = 0 # Assumes tile 0 in your TileSet is red
		Unit.UnitClass.ARCHER:
			tile_id = 1 # Assumes tile 1 is yellow
		Unit.UnitClass.WIZARD:
			tile_id = 2 # Assumes tile 2 is purple
		Unit.UnitClass.SUPPORT:
			tile_id = 3 # Assumes tile 3 is green
	
	for cell in valid_attack_cells:
		highlight_attack_map.set_cellv(cell, tile_id)

func show_skill_range(unit: Unit): # NEW
	hide_all_ranges()
	valid_skill_cells.clear()
	
	var skill = unit.equipped_weapon.unique_skill
	if !skill:
		return
		
	var potential_cells = unit.get_valid_skill_cells()
	
	for cell in potential_cells:
		# Use the skill's built-in validation logic!
		# Pass 'self' as the 'main_node'
		if skill.is_target_valid(unit, cell, self):
			valid_skill_cells.append(cell)
			highlight_map.set_cellv(cell, 2) # Use a different color (e.g., tile 2)

func hide_all_ranges():
	highlight_map.clear()
	highlight_attack_map.clear()
	valid_move_cells.clear()
	valid_attack_cells.clear()
	valid_deployment_cells.clear()
	valid_skill_cells.clear() # NEW
