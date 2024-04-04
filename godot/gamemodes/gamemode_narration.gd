extends Lt2GamemodeBaseClass

func _ready():
	# TODO - Narration
	obj_state.set_gamemode(obj_state.get_gamemode_next())
	completed.emit()
