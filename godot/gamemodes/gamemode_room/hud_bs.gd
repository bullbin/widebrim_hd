extends Control

@onready var _node_screen_controller : Lt2ScreenController = get_parent().node_screen_controller
@onready var _btn_movemode : Lt2GodotAnimatedButtonDeferred = get_node("movemode")

func _ready():
	_node_screen_controller.canvas_resize.connect(_on_canvas_resized)
	_on_canvas_resized()

func _on_canvas_resized():
	size = _node_screen_controller.get_size_bs()
	position = _node_screen_controller.get_anchor_loc_bs()
	_btn_movemode.position = size - _btn_movemode.size
