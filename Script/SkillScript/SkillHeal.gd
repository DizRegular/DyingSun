extends Resource
class_name SkillHeal

# --- Basic Skill Info (all skills have this) ---
export(String) var skill_name = "Skill"
export(int) var ap_cost = 2
export(String, MULTILINE) var description = "" # NEW: For a UI tooltip

# The range of the skill
export(Resource) var skill_pattern # Drag a Pattern.tres file here

# --- "Virtual" Functions ---
# This is the main logic function. It's meant to be overridden
# by child scripts (like SkillDamage.gd).
# We add "pass" so Godot doesn't complain.
func execute(caster: Unit, target_cell: Vector2, main_node: Node2D):
	print("WARNING: Base execute() called. Skill '", skill_name, "' has no logic.")
	pass

# NEW: A helper function to check if a target is valid
# This can also be overridden by child scripts
func is_target_valid(caster: Unit, target_cell: Vector2, main_node: Node2D) -> bool:
	# By default, any cell is valid.
	# A "Heal" skill could override this to only allow targeting allies.
	return true
