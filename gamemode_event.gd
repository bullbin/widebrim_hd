extends Lt2GamemodeBaseClass

@onready var node_script_executor = get_node("script_executor")

# Called when the node enters the scene tree for the first time.
func _ready():
	node_script_executor.script_finished.connect(_terminate)

func _do_on_complete():
	# TODO - Set goal information, do Mokuteki window
	
	if obj_state.id_event_immediate > 0:
		# TODO - One more check
		obj_state.set_gamemode(Lt2Constants.GAMEMODES.DRAMA_EVENT)
		obj_state.id_event = obj_state.id_event_immediate
		obj_state.id_event_immediate = -1
	
		# TODO - BGM fadeout, wait Vsync, fadeout screen, wait Vsync
	else:
		# TODO - BGM fadeout for custom sound set
		# TODO - Check if challenge mode active, do challenge mode
		
		if obj_state.id_event == 18480 and obj_state.get_id_room() == 63:
			# TODO - Remove constants
			obj_state.set_gamemode(Lt2Constants.GAMEMODES.DRAMA_EVENT)
			obj_state.id_event = 18000
		else:
			# TODO - Tea checks, some other checks
			pass
	
	completed.emit()

func _terminate():
	node_screen_controller.fade_out(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE,
									Callable(self, "_do_on_complete"))

func _unhandled_input(event):
	if node_script_executor.on_touch():
		get_viewport().set_input_as_handled()
