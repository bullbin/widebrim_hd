extends Node2D

const GodotLt2SpriteLoader = preload("res://scripts/lt2_as_godot/node_lt2_anim.gd")
const GodotLt2ScriptPlayer = preload("res://scripts/lt2_as_godot/node_lt2_script_playback.gd")
const Utils = preload("res://utils.gd")

var node_screen_controller 	: Lt2ScreenController 	= null
var obj_state 				: Lt2State 				= null

func load_init(state : Lt2State, screen_controller : Lt2ScreenController):
	node_screen_controller = screen_controller
	obj_state = state # 20023
	obj_state.id_event = 10030
	# obj_state.id_event = 16020

# Called when the node enters the scene tree for the first time.
func _ready():
	#var gds_test 	= Lt2AssetScript.new("res://assets/data/event/e20_010.gds", false)
	#var debug 		= GodotLt2ScriptPlayer.new(obj_state, node_screen_controller, gds_test)
	#add_child(debug)
	pass
	#var node_twindow = Lt2GodotAnimation.new("event/twindow.arc")
	#get_node("root_character").add_child(node_twindow)
	#node_twindow.translate(node_twindow.get_variable_as_vector_from_name("pos"))
	#node_twindow.set_animation_from_index(5)
	#get_node("script_executor").resume_exectution()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
