extends Lt2GodotScriptBase

# TODO - These are stored with a slash at beginning
const PATH_EVENT_SCRIPT : String = "event/e%d_%03d.gds"
const PATH_EVENT_DATA	: String = "event/d%d_%03d.dat"
const PATH_ANIM_CHAR	: String = "eventchr/chr%d.arc"

var _data 		: Lt2AssetEventData 			= null
var _characters : Array[Lt2GodotCharController] = []

const EVENT_LIMIT_TEA = 30000
const EVENT_LIMIT_PUZZLE = 20000

@onready var _node_twindow = get_parent().get_node("twindow")

func _char_in_slot(idx_char) -> bool:
	return 0 <= idx_char and idx_char < len(_characters)

func _init():
	super(null, null, null)

func _ready():
	var state : Lt2State = get_parent().obj_state
	var screen_controller : Lt2ScreenController = get_parent().node_screen_controller
	var id_event_main = state.id_event / 1000
	var id_event_sub = state.id_event % 1000
	
	# TODO - Conditions (see widebrim)
	state.set_gamemode(Lt2Constants.GAMEMODES.ROOM)
	
	var path_script = PATH_EVENT_SCRIPT % [id_event_main, id_event_sub]
	var path_data = PATH_EVENT_DATA % [id_event_main, id_event_sub]
	
	var script = Lt2AssetScript.new(path_script, false)
	_data = Lt2AssetEventData.new(path_data)
	
	load_init(state, get_parent().node_screen_controller, script)
	
	# TODO - Inaccuracy, this needs to be held global state
	var ev_inf_id_sound = 0
	var ev_inf_entry = state.dlz_ev_inf2.find_entry(state.id_event)
	if ev_inf_entry != null:
		# TODO - Unknown when this is done, also should not be done here (room only...) with storyflag
		if ev_inf_entry.idx_event_viewed != -1:
			state.flags_event_viewed.set_bit(ev_inf_entry.idx_event_viewed, true)
		
		# LoadEvent
		if state.id_event >= EVENT_LIMIT_PUZZLE and state.id_event < EVENT_LIMIT_TEA and ev_inf_entry.data_puzzle != -1:
			state.set_puzzle_id(ev_inf_entry.data_puzzle)
			state.set_gamemode(Lt2Constants.GAMEMODES.PUZZLE)
			state.set_gamemode_next(Lt2Constants.GAMEMODES.END_PUZZLE)
		ev_inf_id_sound = ev_inf_entry.data_sound_set
		
		if ev_inf_entry.idx_story_flag != -1:
			print("Story flag set.")
			state.flags_storyflag.set_bit(ev_inf_entry.idx_story_flag, true)
	
	for idx_char in range(8):
		_characters.append(Lt2GodotCharController.new(_data.characters[idx_char]))
		get_parent().get_node("root_character").add_child(_characters[idx_char])
		
		_characters[idx_char].set_animation_from_index(_data.characters_idx_anim[idx_char])
		_characters[idx_char].set_visibility(_data.characters_visibility[idx_char])
		_characters[idx_char].set_char_position(_data.characters_slot[idx_char])
	
	# REF - LoadEvent
	screen_controller.set_background_bs("map/main%d.bgx" % _data.map_id_bs)
	screen_controller.set_background_ts("event/sub%d.bgx" % _data.map_id_ts)
	# TODO - Nullify held event ID
	if _data.custom_sound_set != 2 and _data.intro_mode != 3:
		# Load BGM from ID
		SoundController.load_environment(state.dlz_snd_fix, ev_inf_id_sound, true)
	else:
		# TODO - Unknown mode, potentially queue BGM but do not play yet
		SoundController.load_environment(state.dlz_snd_fix, ev_inf_id_sound, false)
		if _data.intro_mode == 3:
			SoundController.stop_bgm()
		else:
			state.id_held_bgm = ev_inf_id_sound
	
	_node_twindow.build_character_map(_data, _characters)
	
	# Do
	match _data.intro_mode:
		1:
			pass
		2:
			await screen_controller.fade_in_bs_async(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE)
		3, 0:
			screen_controller.set_background_bs_overlay(120)
			await screen_controller.fade_in_async(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE)
		_:
			screen_controller.fade_in_async(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE)

func _execute_instruction(opcode : int, operands : Array) -> bool:
	var known = await super(opcode, operands)
	if not(known):
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
					var duration_in_frames : float = 20.0
					if operands[1] != 0:
						duration_in_frames = (32.0 / abs(operands[1])) + 4
					duration_in_frames *= Lt2Constants.TIMING_LT2_TO_MILLISECONDS
					_characters[operands[0]].fade_visibility(operands[1] >= 0, duration_in_frames, Callable())
					await get_tree().create_timer(duration_in_frames).timeout
			
			Lt2Constants.SCRIPT_OPERANDS.TEXT_WINDOW:
				_node_twindow.load_talkscript(operands[0])
				_node_twindow.switch_to_dialogue()
				await _node_twindow.completed
			
			Lt2Constants.SCRIPT_OPERANDS.SET_VOICE_ID:
				_state.id_voice = operands[0]
			
			Lt2Constants.SCRIPT_OPERANDS.WAIT_FRAME2:
				var entry = _state.dlz_tm_def.find_entry(operands[0])
				if entry != null:
					await get_tree().create_timer(entry.count_frames * Lt2Constants.TIMING_LT2_TO_MILLISECONDS).timeout
			
			Lt2Constants.SCRIPT_OPERANDS.PLAY_SOUND:
				SoundController.play_sfx(Lt2Utils.get_synth_audio_from_sfx_id(operands[0]))
			
			Lt2Constants.SCRIPT_OPERANDS.PLAY_STREAM:
				SoundController.play_sfx(Lt2Utils.get_sample_audio_from_sfx_id(operands[0]))
			
			Lt2Constants.SCRIPT_OPERANDS.ENV_STOP:
				SoundController.stop_env()
			
			Lt2Constants.SCRIPT_OPERANDS.ENV_PLAY:
				SoundController.play_env(operands[0])
			
			# TODO - Research this, not enough known about audio subsystem
			Lt2Constants.SCRIPT_OPERANDS.FADE_IN_BGM:
				if operands[0] != 1:
					print("Audio: FadeInBgm unimplemented operand", operands[0])
				
				SoundController.fade_bgm_2(1, operands[1] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
			
			Lt2Constants.SCRIPT_OPERANDS.FADE_OUT_BGM:
				if operands[0] != 0:
					print("Audio: FadeOutBgm unimplemented operand", operands[0])
				
				SoundController.fade_bgm_2(0, operands[1] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
			
			# TODO - Audio fading - does this pause execution? Strange timing in 10030
			Lt2Constants.SCRIPT_OPERANDS.FADE_IN_BGM2:
				if operands[0] != 1:
					print("Audio: FadeInBgm2 unimplemented operand", operands[0])
				
				var entry = _state.dlz_tm_def.find_entry(operands[1])
				if entry != null:
					var fade_time = entry.count_frames * Lt2Constants.TIMING_LT2_TO_MILLISECONDS
					SoundController.fade_bgm_2(1, fade_time)
			
			Lt2Constants.SCRIPT_OPERANDS.FADE_OUT_BGM2:
				if operands[0] != 0:
					print("Audio: FadeOutBgm2 unimplemented operand", operands[0])
				
				var entry = _state.dlz_tm_def.find_entry(operands[1])
				if entry != null:
					var fade_time = entry.count_frames * Lt2Constants.TIMING_LT2_TO_MILLISECONDS
					SoundController.fade_bgm_2(0, fade_time)
			
			Lt2Constants.SCRIPT_OPERANDS.PLAY_BGM:
				if operands[1] != 1:
					print("Audio: BGM queueing unimplemented!")
				if operands[2] != 0:
					print("Audio: BGM unknown PLAY_BGM operands", operands)
				
				SoundController.play_bgm(operands[0])
			_:
				return false
	return true
