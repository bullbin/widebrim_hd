extends Object

const MAGIC_VARIABLE : int = 4660

var _name 		: String 		= "Create an Animation"
var _frames 	: Array[int] 	= []
var _durations 	: Array[int] 	= []

func _init(name_animation : String):
	_name = name_animation
	
func _to_string() -> String:
	return _name

func add_frame(idx_frame : int, duration : int) -> bool:
	if idx_frame < 0 or duration < 0:
		return false

	_frames.append(idx_frame)
	_durations.append(duration)
	return true

func get_name():
	return _name

func get_count_frames():
	return len(_frames)

func get_frame(idx_frame : int) -> int:
	if idx_frame < 0 or idx_frame >= len(_frames):
		return _frames[idx_frame]
	return -1

func get_duration(idx_frame : int) -> int:
	if idx_frame < 0 or idx_frame >= len(_frames):
		return _durations[idx_frame]
	return -1
