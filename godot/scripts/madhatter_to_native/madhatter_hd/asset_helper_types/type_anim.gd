class_name Lt2TypeAnimation

extends Object

const MAGIC_VARIABLE : int = 4660

var _name 		: String 		= "Create an Animation"
var _frames 	: Array[int] 	= []
var _durations 	: Array[int] 	= []
var _sub_offset : Vector2i		= Vector2i.ZERO
var _sub_anim	: int			= -1

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

func set_subanim_params(offset : Vector2i, idx_anim : int):
	_sub_offset = offset
	_sub_anim = idx_anim

func get_name():
	return _name

func get_count_frames():
	return len(_frames)

func get_frame(idx_frame : int) -> int:
	if idx_frame < 0 or idx_frame >= len(_frames):
		return -1
	return _frames[idx_frame]

func get_duration(idx_frame : int) -> int:
	if idx_frame < 0 or idx_frame >= len(_frames):
		return -1
	return _durations[idx_frame]

func get_subanim_offset() -> Vector2i:
	return _sub_offset

func get_subanim_index() -> int:
	return _sub_anim
