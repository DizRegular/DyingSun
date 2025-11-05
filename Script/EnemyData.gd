extends Resource
class_name EnemyData

# This resource defines a single enemy to be spawned.
# You can create multiple .tres files from this script.

export(PackedScene) var unit_scene # The Enemy's Unit.tscn
export(Resource) var weapon       # The Weapon.tres to equip them with
export(Vector2) var spawn_position # The grid cell (e.g., (8, 5))
