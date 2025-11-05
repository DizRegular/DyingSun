extends HBoxContainer

# This will be set by Main.gd
var main_script = null

func can_drop_data(position, data):
	if main_script:
		return main_script.can_drop_data_on_party(position, data, self)
	return false

func drop_data(position, data):
	if main_script:
		main_script.drop_data_on_party(position, data, self)
