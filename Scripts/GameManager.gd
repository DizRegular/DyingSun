extends Node

# Define states for our game
enum TurnState { DEPLOYMENT, PLAYER_TURN, ENEMY_TURN }

var current_state = TurnState.DEPLOYMENT

# player_units holds units ON THE MAP
var player_units = [] 
var enemy_units = []

# This holds the PackedScenes of units waiting to be deployed
var player_party_scenes = []

func _ready():
	pass

func set_player_party(scenes: Array):
	player_party_scenes = scenes

func start_game(p_units, e_units):
	player_units = p_units
	enemy_units = e_units
	# The game now starts in the DEPLOYMENT state
	current_state = TurnState.DEPLOYMENT
	print("Deployment phase starts!")

func finish_deployment():
	# Called by Main.gd when "End Deployment" is clicked
	if current_state == TurnState.DEPLOYMENT:
		start_player_turn()

func start_player_turn():
	print("Player turn starts!")
	current_state = TurnState.PLAYER_TURN
	# Reset AP for all *deployed* player units
	for unit in player_units:
		unit.reset_ap()

func start_enemy_turn():
	print("Enemy turn starts!")
	current_state = TurnState.ENEMY_TURN
	# ... (Add your AI logic here) ...
	# For now, just end the enemy turn immediately
	end_turn()

func end_turn():
	if current_state == TurnState.PLAYER_TURN:
		start_enemy_turn()
	else:
		start_player_turn()
