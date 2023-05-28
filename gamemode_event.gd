extends Lt2GamemodeBaseClass

func load_init(state : Lt2State, screen_controller : Lt2ScreenController):
	super.load_init(state, screen_controller)
	obj_state.id_event = 10030

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("script_executor").script_finished.connect(_terminate)

func _do_on_complete():
	completed.emit()

func _terminate():
	node_screen_controller.fade_out(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE,
									Callable(self, "_do_on_complete"))
