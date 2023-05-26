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
	
	node_screen_controller.configure_room_mode()
	
	DisplayServer.window_set_size(Lt2Constants.RESOLUTION_TARGET / 2)
	
	var gamemode = load("res://gamemode_event.tscn").instantiate()
	gamemode.load_init(state, node_screen_controller)
	node_gamemode.add_child(gamemode)
