extends Node

enum TurnState { DEPLOYMENT, PLAYER_TURN, ENEMY_TURN }
var current_state = TurnState.DEPLOYMENT

# --- Deployed Units (on map) ---
var player_units = [] 
var enemy_units = []

# --- Rosters (not on map) ---
# This holds the PartyMember.tres resources
var player_party = []
# This holds the Weapon.tres resources
var weapon_inventory = []

func _ready():
	pass

# --- NEW FUNCTIONS ---
func set_player_party(party: Array):
	# We duplicate to avoid modifying the original exported resources
	for member in party:
		player_party.append(member.duplicate())

func set_weapon_inventory(weapons: Array):
	# We duplicate to avoid modifying the original exported resources
	for weapon in weapons:
		weapon_inventory.append(weapon.duplicate())
# ---

func start_game(p_units, e_units):
	player_units = p_units
	enemy_units = e_units
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
	print("Enemy turn starts!")
	current_state = TurnState.ENEMY_TURN
	end_turn()

func end_turn():
	if current_state == TurnState.PLAYER_TURN:
		start_enemy_turn()
	else:
		start_player_turn()
