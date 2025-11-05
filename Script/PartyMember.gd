extends Resource
class_name PartyMember

# This must match the enum in Unit.gd
enum UnitClass { WARRIOR, ARCHER, WIZARD, SUPPORT }

# --- Unit Data ---
export(String) var unit_name = "Unit"
export(Texture) var unit_picture # For UI portrait
export(PackedScene) var unit_scene # The Unit.tscn
export(UnitClass) var unit_class = UnitClass.WARRIOR # MUST match the class in the scene

# --- Runtime Equipment ---
# This is set at runtime during the deployment phase by dragging
var equipped_weapon: Weapon = null
