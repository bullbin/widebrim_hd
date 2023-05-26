extends Lt2GodotScriptBase

# TODO - These are stored with a slash at beginning
const PATH_EVENT_SCRIPT : String = "event/e%d_%03d.gds"
const PATH_EVENT_DATA	: String = "event/d%d_%03d.dat"
const PATH_ANIM_CHAR	: String = "eventchr/chr%d.arc"

var _data 		: Lt2AssetEventData 			= null
var _characters : Array[Lt2GodotCharController] = []

@onready var _node_twindow = get_parent().get_node("twindow")

func _char_in_slot(idx_char) -> bool:
	return 0 <= idx_char and idx_char < len(_characters)

func _init():
	super(null, null, null)

func _ready():
	var state = get_parent().obj_state
	var screen_controller : Lt2ScreenController = get_parent().node_screen_controller
	var id_event_main = state.id_event / 1000
	var id_event_sub = state.id_event % 1000
	
	var path_script = PATH_EVENT_SCRIPT % [id_event_main, id_event_sub]
	var path_data = PATH_EVENT_DATA % [id_event_main, id_event_sub]
	
	var script = Lt2AssetScript.new(path_script, false)
	_data = Lt2AssetEventData.new(path_data)
	
	load_init(state, get_parent().node_screen_controller, script)
	
	for idx_char in range(8):
		_characters.append(Lt2GodotCharController.new(_data.characters[idx_char]))
		get_parent().get_node("root_character").add_child(_characters[idx_char])
		
		_characters[idx_char].set_animation_from_index(_data.characters_idx_anim[idx_char])
		_characters[idx_char].set_visibility(_data.characters_visibility[idx_char])
		_characters[idx_char].set_char_position(_data.characters_slot[idx_char])
	
	if _data.map_id_bs != 0:
		screen_controller.set_background_bs("map/main%d.bgx" % _data.map_id_bs)
	if _data.map_id_ts != 0:
		screen_controller.set_background_bs("event/sub%d.bgx" % _data.map_id_ts)
	
	_node_twindow.build_character_map(_data, _characters)
	_node_twindow.completed.connect(resume_execution)
	
	match _data.intro_mode:
		1:
			resume_execution()
		2:
			screen_controller.fade_in_bs(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE, Callable(self, "resume_execution"))
		3, 0:
			screen_controller.set_background_bs_overlay(120)
			screen_controller.fade_in(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE, Callable(self, "resume_execution"))
		_:
			screen_controller.fade_in(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE, Callable(self, "resume_execution"))

func _execute_instruction(opcode : int, operands : Array) -> bool:
	if not(super(opcode, operands)):
		match opcode:
			Lt2Constants.SCRIPT_OPERANDS.SPRITE_ON:
				if _char_in_slot(operands[0]):
					_characters[operands[0]].set_visibility(true)
			Lt2Constants.SCRIPT_OPERANDS.SPRITE_OFF:
				if _char_in_slot(operands[0]):
					_characters[operands[0]].set_visibility(false)
			Lt2Constants.SCRIPT_OPERANDS.SET_SPRITE_POS:
				if _char_in_slot(operands[0]):
					_characters[operands[0]].set_char_position(operands[1])
			Lt2Constants.SCRIPT_OPERANDS.SET_SPRITE_ANIMATION:
				if operands[0] in _data.characters:
					_characters[_data.characters.find(operands[0])].set_animation_from_name(operands[1])
			Lt2Constants.SCRIPT_OPERANDS.DO_SPRITE_FADE:
				if _char_in_slot(operands[0]):
					pause_execution()
					var duration_in_frames : float = 20.0
					if operands[1] != 0:
						duration_in_frames = (32.0 / abs(operands[1])) + 4
					duration_in_frames *= Lt2Constants.TIMING_LT2_TO_MILLISECONDS
					_characters[operands[0]].fade_visibility(operands[1] >= 0, duration_in_frames,
															 Callable(self, "resume_execution"))
			
			Lt2Constants.SCRIPT_OPERANDS.TEXT_WINDOW:
				_node_twindow.load_talkscript(operands[0])
				_node_twindow.switch_to_dialogue()
				pause_execution()
			
			Lt2Constants.SCRIPT_OPERANDS.SET_VOICE_ID:
				_state.id_voice = operands[0]
			
			_:
				return false
	return true
