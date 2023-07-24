extends Control

const OFFSET_TOBJ_TEXT	: int = 90

@onready var node_window 	: Lt2GodotAnimationDeferred = get_node("tobj_window")
@onready var node_icon 		: Lt2GodotAnimationDeferred = get_node("tobj_window/icon")
@onready var node_wait 		: Lt2GodotAnimationDeferred = get_node("tobj_window/cursor_wait")
@onready var node_text		: Label 					= get_node("tobj_window/text")
@onready var _node_screen_controller : Lt2ScreenController = get_parent().node_screen_controller

func _ready():
	_node_screen_controller.canvas_resize.connect(center_tobj)
	center_tobj()
	
	# TODO - Stored position is fairly different, 254,156
	var icon_position = Vector2i(16, node_window.get_maximal_dimensions().y - node_icon.get_maximal_dimensions().y)
	icon_position.y /= 2
	var wait_position = node_window.get_maximal_dimensions() - node_wait.get_maximal_dimensions()
	wait_position.x -= 12
	wait_position.y -= 9
	
	node_window.set_animation_from_index(1)
	node_icon.set_flippable_position(icon_position)
	node_icon.set_animation_from_index(3)
	
	node_wait.set_flippable_position(wait_position)
	node_wait.set_animation_from_index(1)
	
	node_text.position.x = OFFSET_TOBJ_TEXT
	node_text.size = node_window.get_maximal_dimensions()
	node_text.size.x -= node_text.position.x

func center_tobj():
	position.x = - node_window.get_maximal_dimensions().x / 2
	position.y = _node_screen_controller.get_anchor_loc_bs().y + _node_screen_controller.get_size_bs().y / 2 - node_window.get_maximal_dimensions().y / 2
