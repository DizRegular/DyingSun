extends Button
class_name WeaponDragButton

# This will be set by Main.gd
var weapon: Weapon = null

# These are the class colors from Main.gd
# (We need to duplicate them here for the preview)
const CLASS_COLORS = {
	0: Color(1.0, 0.4, 0.4), # MELEE (Red)
	1: Color(1.0, 1.0, 0.4), # ARCHER (Yellow)
	2: Color(0.8, 0.4, 1.0), # WIZARD (Purple)
	3: Color(0.4, 1.0, 0.4)  # SUPPORT (Green)
}

# This function is CALLED BY GODOT automatically when a drag starts
func get_drag_data(position):
	# Prepare the data to be dragged
	var data = {"type": "weapon", "weapon": weapon}
	
	# Create the preview (a copy of the button)
	var preview = Button.new()
	preview.text = weapon.weapon_name
	
	# weapon.weapon_class is an integer (0, 1, 2, or 3) from the enum
	preview.set_modulate(CLASS_COLORS[weapon.weapon_class])
	
	# Set the preview
	set_drag_preview(preview)
	print("Dragging: ", weapon.weapon_name)
	# Return the data to start the drag
	return data
