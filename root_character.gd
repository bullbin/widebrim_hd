extends Control

@onready var _screen_controller : Lt2ScreenController = get_parent().node_screen_controller

func _ready():
	_screen_controller.canvas_resize.connect(_update_position)
	_update_position()
	
func _update_position():
	position = _screen_controller.get_anchor_loc_bs_full_corner()
