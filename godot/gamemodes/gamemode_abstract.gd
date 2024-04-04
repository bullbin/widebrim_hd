class_name Lt2GamemodeBaseClass

extends Node2D
signal completed

var node_screen_controller 	: Lt2ScreenController 	= null
var obj_state 				: Lt2State 				= null

func load_init(state : Lt2State, screen_controller : Lt2ScreenController):
	node_screen_controller = screen_controller
	obj_state = state
