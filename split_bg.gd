extends Control

# Assumed not to changed... maybe set dynamically?
const SIZE_BOTTOM = 620
const SIZE_TOP = 632
const MIN_BOTTOM = 568

# Stored inside ROM, some values that control viewport scaling
const X_MIN = 640
const X_MAX = 768
const Y_MIN = 1024
const Y_MED_STOP_SCALE = 1136
const Y_MAX = 1252

var _in_room_mode : bool = false

signal ratio_changed

@onready var tex_top : Control = get_node("VBoxContainer/mask_ts/bg_ts")
@onready var node_bottom : Control = get_node("VBoxContainer/mask_bs")
@onready var node_top : Control = get_node("VBoxContainer/mask_ts")

func set_room_mode_state(in_room_mode : bool):
	if _in_room_mode != in_room_mode:
		_in_room_mode = in_room_mode
		correct_bottom_screen()

func correct_bottom_screen():
	set_position(- (size / 2))
	
	if size.y < Y_MED_STOP_SCALE:
		# At smaller resolutions, during event mode, pictures are attached from bottom up.
		# Other than that, usually we center fill like normal.
		var proportion = float(size.y - Y_MIN) / (Y_MED_STOP_SCALE - Y_MIN)
		var diff = SIZE_BOTTOM - MIN_BOTTOM
		var new_bottom_height = MIN_BOTTOM + (proportion * diff)
		node_bottom.custom_minimum_size.y = round(new_bottom_height)
	else:
		node_bottom.custom_minimum_size.y = SIZE_BOTTOM
	
	node_top.custom_minimum_size.y = size.y - node_bottom.custom_minimum_size.y
	
	if _in_room_mode:
		# If in room mode, center the top image like normal
		tex_top.position.y = 0
	else:
		# Game attempts to align top and bottom images - for some reason, this is
		#     not completed properly at lower resolutions
		var offset_image = SIZE_TOP - (size.y - node_bottom.custom_minimum_size.y)
		tex_top.position.y = -offset_image / 2

		# At lowest resolution, blend toward faulty placement for better accuracy
		if size.y < Y_MED_STOP_SCALE:
			var proportion = float(size.y - Y_MIN) / (Y_MED_STOP_SCALE - Y_MIN)
			tex_top.position.y *= proportion
	
	ratio_changed.emit()
