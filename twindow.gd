extends Node2D

signal completed

const PATH_TALKSCRIPT : String = "event/t%d_%03d_%d.txt"

@onready var _node_window = Lt2GodotAnimation.new("event/twindow.spr", get_node("CanvasGroup"))
@onready var _node_reward = Lt2GodotAnimation.new("event/mokuteki_w.spr", get_node("CanvasGroup"))
@onready var _node_text : Label = get_node("text")

var _node_fade 	: CanvasFadeController 			= CanvasFadeController.new()
var _chars 		: Array[Lt2GodotCharController] = []
var _data		: Lt2AssetEventData 			= null

@onready var _state : Lt2State = get_parent().obj_state

var _text_complete 	: String 	= ""
var _idx_char 		: int 		= 0
var _time_visible	: float		= 0
var _awaiting_input : bool		= false
var _completed		: bool		= false

var _target_char	: Lt2GodotCharController = null
var _anim_start		: String	= "NONE"
var _anim_end		: String	= "NONE"
var _pitch			: int		= -1
var _target_voice	: int		= -1
var _idx_voice		: int 		= -1

# Called when the node enters the scene tree for the first time.
func _ready():
	_node_reward.set_animation_from_index(1)
	_node_window.set_animation_from_index(1)
	_node_reward.set_transparency(0.0)
	_node_window.set_transparency(0.0)
	_node_text.hide()
	get_node("CanvasGroup").self_modulate.a = 0.0
	get_node("CanvasGroup").add_child(_node_fade)

func _position_text_dialogue():
	_node_text.position = Vector2(42,45)
	_node_text.show()
	do_on_resume()

func _position_text_reward():
	_node_text.position = Vector2(42,18)
	_node_text.show()

func play_voiceline():
	if _target_voice != -1 and _idx_voice != -1:
		print("TODO: Voiceline %03d_%d" % [_target_voice, _idx_voice])

func stop_active_voiceline():
	pass

func do_on_resume():
	stop_active_voiceline()
	if _idx_char < len(_text_complete):
		_idx_voice += 1
		play_voiceline()

func _reset_state():
	_time_visible = 0
	_node_text.text = ""
	_idx_char = 0
	_target_char = null
	_target_voice = -1
	_idx_voice = -1
	_completed = false

func switch_to_reward():
	@warning_ignore("integer_division")
	global_position.x = _node_reward.get_variable_as_vector_from_index(0).x - Lt2Constants.RESOLUTION_TARGET.x/2
	@warning_ignore("integer_division")
	global_position.y = (Lt2Constants.RESOLUTION_TARGET.y/ 2) - _node_reward.get_maximal_dimensions().y
	_node_reward.set_transparency(1.0)
	_node_window.set_transparency(0.0)
	_node_fade.fade_visibility(1.0, 0.5, Callable(self, "_position_text_reward"))
	_reset_state()

func switch_to_dialogue():
	@warning_ignore("integer_division")
	global_position.x = _node_window.get_variable_as_vector_from_index(0).x - Lt2Constants.RESOLUTION_TARGET.x/2
	@warning_ignore("integer_division")
	global_position.y = (Lt2Constants.RESOLUTION_TARGET.y/ 2) - _node_window.get_maximal_dimensions().y
	_node_window.set_transparency(1.0)
	_node_reward.set_transparency(0.0)
	_node_fade.fade_visibility(1.0, 0.5, Callable(self, "_position_text_dialogue"))
	
	if _target_char != null and not(Lt2Utils.lt2_string_compare(_anim_start, "NONE")):
		_target_char.set_animation_from_name(_anim_start)

func build_character_map(data : Lt2AssetEventData, characters : Array[Lt2GodotCharController]):
	_data = data
	_chars = characters

func load_talkscript(id : int):
	var event_group = _state.id_event / 1000
	var event_subgroup = _state.id_event % 1000
	_reset_state()
	_target_voice = _state.id_voice
	_state.id_voice = -1
	
	var raw_text = FileAccess.open(Lt2Utils.get_asset_path(PATH_TALKSCRIPT % [event_group, event_subgroup, id]), FileAccess.READ)
	if raw_text != null:
		_text_complete = raw_text.get_as_text()
		raw_text.close()
		var encoded = _text_complete.split("|")
		
		_anim_start = encoded[1]
		_anim_end = encoded[2]
		_pitch = int(encoded[3])
		_text_complete = encoded[4]
		
		if int(encoded[0]) in _data.characters:
			_target_char = _chars[_data.characters.find(int(encoded[0]))]

func get_next_token() -> String:
	var remaining = len(_text_complete) - _idx_char
	if remaining <= 0:
		return ""
	
	# TODO - Join newline if needed
	var output = _text_complete[_idx_char]
	_idx_char += 1
	
	match output:
		"@":
			if remaining > 1:
				match _text_complete[_idx_char].to_lower():
					"p", "w", "c":
						_idx_char += 1
						return output + _text_complete[_idx_char - 1]
					"v":
						_idx_char += 2
						if remaining > 2:
							return output + _text_complete[_idx_char - 2] + _text_complete[_idx_char - 1]
					_:
						_idx_char += 1
				return ""
		"#":
			# Color change
			if remaining > 1:
				_idx_char += 1
				return output + _text_complete[_idx_char - 1]
			return ""
		"&":
			# SetAni
			pass
		_:
			return output
	
	return output

func apply_token_command(token : String) -> bool:
	if len(token) == 0:
		return false
	
	match token[0]:
		"@":
			match token[1].to_lower():
				"p":
					_awaiting_input = true
					if _target_char != null:
						_target_char.set_talk_state(false)
				"v":
					var count_frames = token[2].to_ascii_buffer()[0] - 48
					count_frames = min(max(0, count_frames), 127) * 10
					_time_visible -= Lt2Constants.TIMING_LT2_TO_MILLISECONDS * count_frames
					if _target_char != null:
						_target_char.set_talk_state(false)
				"c":
					_node_text.text = ""
					_idx_char += 2	# TODO - not sure why this is two...
				"w":
					_time_visible -= 0.5
					if _target_char != null:
						_target_char.set_talk_state(false)
		"#":
			pass
		"&":
			pass
		_:
			return false
	
	return true

func _emit_on_done():
	emit_signal("completed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _idx_char < len(_text_complete):
		if not(_awaiting_input):
			if _node_text.is_visible():
				_time_visible += delta
				
				while _time_visible > Lt2Constants.TIMING_LT2_TO_MILLISECONDS and not(_awaiting_input):
					var token = get_next_token()
					if not(apply_token_command(token)):
						if _target_char != null:
							_target_char.set_talk_state(true)
							
						_node_text.text += token
						_time_visible -= Lt2Constants.TIMING_LT2_TO_MILLISECONDS
				
				# Done!
				if _idx_char >= len(_text_complete):
					if _target_char != null:
						if not(Lt2Utils.lt2_string_compare(_anim_end, "NONE")):
							_target_char.set_animation_from_name(_anim_end)
						_target_char.set_talk_state(false)
					
					_awaiting_input = true
					_completed = true
	
	elif not(_awaiting_input) and _completed:
		_node_text.hide()
		_node_fade.fade_visibility(0.0, 0.5, Callable(self, "_emit_on_done"))
		_completed = false
		
	_node_window._process(delta)

func is_voiceline_done():
	return true

func skip():
	while not(_awaiting_input) and _idx_char < len(_text_complete):
		var token = get_next_token()
		if not(apply_token_command(token)):
			if _target_char != null:
				_target_char.set_talk_state(true)
				
			_node_text.text += token
	
	if is_voiceline_done() and _target_char != null:
		# TODO - Ensure ending animation is preserved!
		_target_char.set_talk_state(false)

func _unhandled_input(event):
	if _awaiting_input:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_awaiting_input = false
			do_on_resume()
			get_viewport().set_input_as_handled()
	#else:
#		skip()
