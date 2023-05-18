class_name Lt2State

extends Lt2AssetSaveSlot

var id_event : int = 0
var id_movie : int = 0

var _gamemode 		: Lt2Constants.GAMEMODES = Lt2Constants.GAMEMODES.INVALID
var _gamemode_next 	: Lt2Constants.GAMEMODES = Lt2Constants.GAMEMODES.INVALID

var first_touch_enabled : bool = false

func _init():
	super()

func set_gamemode(gamemode : Lt2Constants.GAMEMODES):
	if Lt2Constants.GAMEMODES.find_key(gamemode) != null:
		_gamemode = gamemode
		return true
	_gamemode = Lt2Constants.GAMEMODES.INVALID
	return false
	
func set_gamemode_next(gamemode : Lt2Constants.GAMEMODES):
	if Lt2Constants.GAMEMODES.find_key(gamemode) != null:
		_gamemode_next = gamemode
		return true
	_gamemode_next = Lt2Constants.GAMEMODES.INVALID
	return false

func get_gamemode() -> Lt2Constants.GAMEMODES:
	return _gamemode

func get_gamemode_next() -> Lt2Constants.GAMEMODES:
	return _gamemode_next

func set_id_room(id : int):
	if id != get_id_room():
		id_event_held_autoevent = -1
	super(id)
