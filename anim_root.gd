extends Control

@onready var _node_screen_controller : Lt2ScreenController = get_parent().node_screen_controller

func _ready():
	_node_screen_controller.canvas_resize.connect(fix_position)
	fix_position()

func fix_position():
	position = _node_screen_controller.get_anchor_loc_bs_full_corner()
