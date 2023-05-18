extends Node2D

@export var safety_margin : int = 32

@onready var node_gamemode = get_node("control_gamemode")
@onready var node_screen_controller = get_node("screen_controller")
var state = Lt2State.new()

func _ready():
	var node_safe = get_node("debug_safe_area")
	node_safe.size = Lt2Constants.RESOLUTION_TARGET
	node_safe.global_position = -Lt2Constants.RESOLUTION_TARGET / 2
	var node_debug = get_node("debug_bad_area")
	node_debug.size = Lt2Constants.RESOLUTION_TARGET + Vector2i(safety_margin, safety_margin)
	node_debug.global_position = -node_debug.size / 2
	
	for node in [get_node("control_bg/bg_bs"), get_node("control_fade/fade_bs")]:
		node.size.x = Lt2Constants.RESOLUTION_TARGET.x
		node.size.y = Lt2Constants.RESOLUTION_TARGET.y / 2
		node.global_position.x = -Lt2Constants.RESOLUTION_TARGET.x / 2
		node.global_position.y = 0
	
	for node in [get_node("control_bg/bg_ts"), get_node("control_fade/fade_ts")]:
		node.size.x = Lt2Constants.RESOLUTION_TARGET.x
		node.size.y = Lt2Constants.RESOLUTION_TARGET.y / 2
		node.global_position = -Lt2Constants.RESOLUTION_TARGET / 2
	
	DisplayServer.window_set_size(Lt2Constants.RESOLUTION_TARGET / 2)
	
	
	#node_screen_controller.fade_in(0.1, Callable())
	#var test = Lt2GodotAnimation.new("eventchr/chr2.spr")
	#test.set_flip_state(true)
	#add_child(test)
	#test.set_transparency(1.0)
	#test.set_animation_from_name("*b1 normal")
	
	var gamemode = load("res://gamemode_event.tscn").instantiate()
	gamemode.load_init(state, node_screen_controller)
	node_gamemode.add_child(gamemode)
