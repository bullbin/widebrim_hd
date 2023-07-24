extends Node2D

# TODO - Block input events during fade activation

@export var safety_margin : int = 32

@onready var node_gamemode = get_node("control_gamemode")
@onready var node_screen_controller = get_node("screen_controller")
var state = Lt2State.new()
var node_gm : Node2D = null

func _exit_tree():
	if Lt2Constants.DEBUG_SAVE_ENABLE:
		state.write_save(Lt2Constants.DEBUG_SAVE_PATH)
		print("Exported save. Now quitting...")
		
func _ready():
	node_screen_controller.configure_room_mode()
	
	if Lt2Constants.DEBUG_SAVE_ENABLE:
		state.read_save(Lt2Constants.DEBUG_SAVE_PATH)
		print("Save imported.")
	
	state.set_gamemode(Lt2Constants.GAMEMODES.ROOM)
	_main()
	
func _main():
	print("Switch mode: ", Lt2Constants.GAMEMODES.keys()[state.get_gamemode()], " ", state.id_event, " ", state.id_movie, " ", state.get_id_room())
	if node_gm != null:
		node_gm.queue_free()
		node_gm = null
	
	match state.get_gamemode():
		Lt2Constants.GAMEMODES.DRAMA_EVENT:
			node_gm = load("res://gamemode_event.tscn").instantiate()
		Lt2Constants.GAMEMODES.ROOM:
			node_gm = load("res://gamemode_room.tscn").instantiate()
		Lt2Constants.GAMEMODES.NARRATION:
			node_gm = load("res://gamemode_narration.tscn").instantiate()
		Lt2Constants.GAMEMODES.MOVIE:
			node_gm = load("res://gamemode_movie.tscn").instantiate()
		_:
			node_gm = null
	
	if node_gm != null:
		node_gm.completed.connect(_main, CONNECT_DEFERRED)
		node_gm.load_init(state, node_screen_controller)
		node_gamemode.add_child(node_gm)
	else:
		print("State bad!")
