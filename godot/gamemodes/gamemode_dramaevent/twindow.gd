extends Node2D

signal completed

const PATH_TALKSCRIPT 	: String = "event/t%d_%03d_%d.txt"
const PATH_NAMETAG		: String = "eventchr/chr%d_n.spr"
const TIME_BETWEEN_TICK	: float = 0.1

@onready var _node_window = Lt2GodotAnimation.new("event/twindow.spr", get_node("CanvasGroup"))
@onready var _node_reward = Lt2GodotAnimation.new("event/mokuteki_w.spr", get_node("CanvasGroup"))
@onready var _node_text : Label = get_node("text")

var _node_fade 	: CanvasFadeController 			= CanvasFadeController.new()
var _chars 		: Array[Lt2GodotCharController] = []
var _char_names : Array[Lt2GodotAnimation]		= []
var _data		: Lt2AssetEventData 			= null

@onready var _state : Lt2State = get_parent().obj_state
@onready var _screen_controller : Lt2ScreenController = get_parent().node_screen_controller

var _text_complete 	: String 	= ""
var _idx_char 		: int 		= 0
var _time_visible	: float		= 0
var _time_bet_tick	: float		= 0
var _awaiting_input : bool		= false
var _completed		: bool		= false

var _target_char	: Lt2GodotCharController = null
var _target_name	: Lt2GodotAnimation		= null
var _anim_start		: String	= "NONE"
var _anim_end		: String	= "NONE"
var _pitch			: int		= -1
var _target_voice	: int		= -1
var _idx_voice		: int 		= -1
var _in_mode_dial	: bool		= true

var _tick_audio		: AudioStream = null

const POS_TO_ANIM = {0:"LEFT",
					2:"RIGHT",
					3:"LEFT_L",
					4:"LEFT_R",
					5:"RIGHT_L",
					6:"RIGHT_R"}

# Called when the node enters the scene tree for the first time.
func _ready():
	_node_reward.set_transparency(0.0)
	_node_window.set_transparency(0.0)
	_node_reward.set_animation_from_index(1)
	_node_window.set_animation_from_index(1)
	_node_text.hide()
	
	_screen_controller.canvas_resize.connect(_update_position)
	_update_position()
	
	get_node("CanvasGroup").modulate.a = 0.0
	get_node("CanvasGroup").add_child(_node_fade)

func _update_position():
	var size_ref_node = null
	if _in_mode_dial:
		size_ref_node = _node_window
	else:
		size_ref_node = _node_reward
		
	position = _screen_controller.get_anchor_loc_bs()
	position.y += _screen_controller.get_size_bs().y - size_ref_node.size.y
	position.x += (_screen_controller.get_size_bs().x - size_ref_node.size.x) / 2

func _position_text_dialogue():
	_node_text.position = Vector2(42,45)
	_node_text.show()
	do_on_resume()

func _position_text_reward():
	_node_text.position = Vector2(42,18)
	_node_text.show()

func play_voiceline():
	if _target_voice != -1 and _idx_voice != -1:
		SoundController.play_voiceline(_target_voice, _idx_voice, Callable())
		# print("TODO: Voiceline %03d_%d" % [_target_voice, _idx_voice])

func stop_active_voiceline():
	SoundController.stop_voiceline()

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
	_target_name = null
	_target_voice = -1
	_idx_voice = -1
	_completed = false

func switch_to_reward():
	_node_reward.set_animation_from_index(1)
	_node_reward.set_transparency(1.0)
	_node_window.set_transparency(0.0)
	_node_fade.fade_visibility(1.0, 0.5, Callable(self, "_position_text_reward"))
	_in_mode_dial = false
	_update_position()
	_reset_state()

func switch_to_dialogue():
	_node_window.set_transparency(1.0)
	_node_reward.set_transparency(0.0)
	_node_fade.fade_visibility(1.0, 0.5, Callable(self, "_position_text_dialogue"))
	_in_mode_dial = true
	_update_position()
	
	if _target_char != null and not(Lt2Utils.lt2_string_compare(_anim_start, "NONE")):
		_target_char.set_animation_from_name(_anim_start)

func build_character_map(data : Lt2AssetEventData, characters : Array[Lt2GodotCharController]):
	_data = data
	_chars = characters
	
	_char_names.clear()
	var img_name : Lt2GodotAnimation = null
	var pos_window = _node_window.get_variable_as_vector_from_index(0)
	var pos_name = Vector2(0,0)
	for char_id in data.characters:
		img_name = Lt2GodotAnimation.new(PATH_NAMETAG % char_id, get_node("CanvasGroup"))
		img_name.set_animation_from_index(1)
		pos_name = img_name.get_variable_as_vector_from_index(0)
		pos_name = pos_window - pos_name
		pos_name.y -= 9	# TODO - This has got to be in binary somewhere...
		pos_name.x += 6
		img_name.set_flippable_position(pos_name)
		_char_names.append(img_name)

func hide_all_nametags():
	for tag in _char_names:
		tag.set_transparency(0.0)

func load_talkscript(id : int):
	_node_window.set_animation_from_index(1)
	_node_window.set_transparency(1.0)
	@warning_ignore("integer_division")
	var event_group = _state.id_event / 1000
	var event_subgroup = _state.id_event % 1000
	_reset_state()
	_target_voice = _state.id_voice
	_state.id_voice = -1
	hide_all_nametags()
	
	var raw_text = FileAccess.open(Lt2Utils.get_asset_path(PATH_TALKSCRIPT % [event_group, event_subgroup, id]), FileAccess.READ)
	if raw_text != null:
		_text_complete = raw_text.get_as_text()
		raw_text.close()
		
		_text_complete = _text_complete.replace("\r", "")
		var encoded = _text_complete.split("|")
		
		_anim_start = encoded[1]
		_anim_end = encoded[2]
		_pitch = int(encoded[3])
		_text_complete = encoded[4]
		
		if int(encoded[0]) in _data.characters:
			_target_char = _chars[_data.characters.find(int(encoded[0]))]
			_target_name = _char_names[_data.characters.find(int(encoded[0]))]
			_target_name.set_transparency(1.0)
			
		if _target_char != null and _target_char.get_visibility() and _target_char.get_char_position() in POS_TO_ANIM:
			_node_window.set_animation_from_name(POS_TO_ANIM[_target_char.get_char_position()])
		raw_text.close()
		
		var id_sfx : int;
		match _pitch:
			1, 4:
				id_sfx = 0x28
			3, 6:
				id_sfx = 0x2a
			_:
				id_sfx = 0x29
		
		_tick_audio = Lt2Utils.get_synth_audio_from_sfx_id(id_sfx)

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
			var str_control =  "&"
			while len(_text_complete) - _idx_char >= 1:
				str_control += _text_complete[_idx_char]
				_idx_char += 1
				if str_control[-1] == "&":
					break
			return str_control
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
					_idx_char += 1	# TODO - not sure why this is two...
				"w":
					_time_visible -= 0.5
					if _target_char != null:
						_target_char.set_talk_state(false)
		"#":
			print("Skip", token)
		"&":
			print("Skip", token)
		_:
			return false
	
	return true

func _emit_on_done():
	emit_signal("completed")

func _enter_end_state_if_done():
	if _idx_char >= len(_text_complete):
		if _target_char != null:
			if not(Lt2Utils.lt2_string_compare(_anim_end, "NONE")):
				_target_char.set_animation_from_name(_anim_end)
			_target_char.set_talk_state(false)
		
		_awaiting_input = true
		_completed = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _idx_char < len(_text_complete):
		if not(_awaiting_input):
			if _node_text.is_visible():
				_time_visible += delta
				_time_bet_tick += delta
				
				while _time_visible > Lt2Constants.TIMING_LT2_TO_MILLISECONDS and not(_awaiting_input):
					var token = get_next_token()
					# print(token)
					if not(apply_token_command(token)):
						if _target_char != null:
							_target_char.set_talk_state(true)
							
						_node_text.text += token
						_time_visible -= Lt2Constants.TIMING_LT2_TO_MILLISECONDS
						if _time_bet_tick >= TIME_BETWEEN_TICK:
							if _target_voice == -1 or _idx_voice == -1:
								SoundController.play_sfx(_tick_audio)
							_time_bet_tick -= TIME_BETWEEN_TICK
				
				# Done!
				_enter_end_state_if_done()
	
	elif not(_awaiting_input) and _completed:
		_node_text.hide()
		_node_fade.fade_visibility(0.0, 0.5, Callable(self, "_emit_on_done"))
		_completed = false
		
	_node_window._process(delta)
	if _target_name != null:
		_target_name._process(delta)

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
		_target_char.set_talk_state(false)
	
	_enter_end_state_if_done()

func _unhandled_input(event):
	if is_visible() and _node_text.is_visible():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _awaiting_input:
				_awaiting_input = false
				do_on_resume()
				get_viewport().set_input_as_handled()
			else:
				skip()
