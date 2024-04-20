extends Lt2GamemodeBaseClass

var _id_base_event : int = 0
const EVENT_LIMIT_PUZZLE : int = 20000

func load_init(state : Lt2State, screen_controller : Lt2ScreenController):
	super(state, screen_controller)
	
	state.set_gamemode_next(Lt2Constants.GAMEMODES.ROOM)
	_id_base_event = state.id_event
	
	var active_nazo_index_external : int = 0
	if state.active_entry_nz_lst != null:
		active_nazo_index_external = state.active_entry_nz_lst.id_external
	
	var target_event_id : int = state.id_event
	
	# Assuming correct (TODO)
	if active_nazo_index_external == 0x87:
		target_event_id += 3
	else:
		# Not accurate, easier here though
		var nazo_state = state.get_puzzle_state_external(active_nazo_index_external)
		target_event_id += 3
	
	state.id_event = target_event_id
	
	# TODO - Global these paths, this tripped me up
	var node_dramaevent = load("res://godot/gamemodes/gamemode_dramaevent/scene.tscn").instantiate()
	node_dramaevent.completed.connect(_terminate, CONNECT_DEFERRED)
	node_dramaevent.load_init(state, node_screen_controller)
	add_child(node_dramaevent)

func _do_on_complete():
	completed.emit()

func _terminate():
	if obj_state.id_event >= EVENT_LIMIT_PUZZLE:
		obj_state.id_event = _id_base_event
	obj_state.set_gamemode(obj_state.get_gamemode_next())
	node_screen_controller.fade_out(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE,
									Callable(self, "_do_on_complete"))
