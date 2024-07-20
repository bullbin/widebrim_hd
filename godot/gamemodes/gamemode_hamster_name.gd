extends Lt2GamemodeBaseClass



func _ready():
	print("Unimplemented - hamstername")
	# TODO - HamsterName
	obj_state.set_gamemode(Lt2Constants.GAMEMODES.DRAMA_EVENT)
	obj_state.id_event = 11101
	completed.emit()
