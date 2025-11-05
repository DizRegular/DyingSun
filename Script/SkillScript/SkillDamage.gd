extends Skill  # --- IMPORTANT: This MUST extend Skill ---
class_name SkillDamage

# This script is a *type* of Skill.
# You create a .tres file from this script.
# It will inherit skill_name, ap_cost, description, and skill_pattern from Skill.gd

# --- Skill-Specific Properties ---
export(int) var base_power = 8
export(float) var scaling_factor = 0.5 # 50% of attack stat

# --- Overridden "Virtual" Functions ---

# This is the main logic function.
# It overrides the 'execute' function from Skill.gd
func execute(caster: Unit, target_cell: Vector2, main_node: Node2D):
	var target = main_node.get_unit_at(target_cell)
	
	if !target:
		print(skill_name, " hits nothing.")
		return
		
	# A custom damage formula for this skill
	var damage = (caster.get_modified_attack() * scaling_factor) + base_power
	var final_damage = damage - target.get_modified_defense()
	final_damage = max(1, int(final_damage)) # Always do at least 1
	
	print(skill_name, " deals ", final_damage, " damage to ", target.unit_name)
	target.take_damage(final_damage)


# This overrides the 'is_target_valid' function from Skill.gd
func is_target_valid(caster: Unit, target_cell: Vector2, main_node: Node2D) -> bool:
	var target = main_node.get_unit_at(target_cell)
	
	# Rule 1: Cannot target an empty cell
	if !target:
		return false
		
	# Rule 2: Cannot target allies
	# (is_enemy is a bool, so we check if they are different)
	if target.is_enemy == caster.is_enemy:
		return false
		
	# All rules passed, target is valid
	return true
