extends Lt2GamemodeBaseClass

func load_init(state : Lt2State, screen_controller : Lt2ScreenController):
	super(state, screen_controller)
	
	var nazo_state = state.get_puzzle_state_internal(state.active_entry_nz_lst.id)
	if nazo_state != null:
		nazo_state.encountered = true
		nazo_state.solved = true
	
	# TODO - Actually implement this mode!

func _ready():
	obj_state.set_gamemode(obj_state.get_gamemode_next())
	completed.emit()
