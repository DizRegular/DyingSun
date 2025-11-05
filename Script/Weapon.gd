extends Resource
class_name Weapon

# This must match the enum in Unit.gd
enum WeaponClass { WARRIOR, ARCHER, WIZARD, SUPPORT }

# --- Weapon Info ---
export(String) var weapon_name = "Weapon"
export(Texture) var weapon_icon # For inventory UI
export(WeaponClass) var weapon_class = WeaponClass.WARRIOR

# --- Stat Modifiers ---
# 1.0 = no change, 1.2 = 20% boost, 0.8 = 20% reduction
export(float) var hp_multiplier = 1.0
export(float) var atk_multiplier = 1.0
export(float) var def_multiplier = 1.0

# --- Patterns & Skills ---
# The weapon, not the unit, now controls the attack range
export(Resource) var attack_pattern # Drag your Pattern.tres file here
export(Resource) var unique_skill = null # Placeholder for later
