extends Lt2GodotScriptBase

# TODO - These are stored with a slash at beginning
const PATH_EVENT_SCRIPT : String = "event/e%d_%03d.gds"
const PATH_EVENT_DATA	: String = "event/d%d_%03d.dat"
const PATH_ANIM_CHAR	: String = "eventchr/chr%d.arc"

var _data : Lt2AssetEventData = null
var _characters = []

func _init():
	super(null, null, null)

func _ready():
	var state = get_parent().obj_state
	var screen_controller : Lt2ScreenController = get_parent().node_screen_controller
	var id_event_main = state.id_event / 1000
	var id_event_sub = state.id_event % 1000
	
	var path_script = Utils.get_asset_root() % (PATH_EVENT_SCRIPT % [id_event_main, id_event_sub])
	var path_data = Utils.get_asset_root() % (PATH_EVENT_DATA % [id_event_main, id_event_sub])
	
	var script = Lt2AssetScript.new(path_script, false)
	var _data = Lt2AssetEventData.new(path_data)
	
	load_init(state, get_parent().node_screen_controller, script)
	
	for idx_char in range(8):
		# TODO - Language dependent!
		_characters.append(Lt2GodotAnimation.new(PATH_ANIM_CHAR % _data.characters[idx_char]))
		_characters[idx_char].set_animation_from_index(_data.characters_idx_anim[idx_char])
		get_parent().get_node("root_character").add_child(_characters[idx_char])
	
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
		
			_:
				return false
	return true
