extends CanvasGroup

@onready var node_window 	: Lt2GodotAnimationDeferred = get_node("tobj_window")
@onready var node_window : Lt2GodotAnimation = Lt2GodotAnimation.new("event/twindow.spr", get
@onready var node_icon 		: Lt2GodotAnimationDeferred = get_node("tobj_window/icon")
@onready var node_wait 		: Lt2GodotAnimationDeferred = get_node("tobj_window/cursor_wait")
@onready var node_text		: Label 					= get_node("tobj_window/text")
@onready var _node_screen_controller : Lt2ScreenController = get_parent().node_screen_controller
