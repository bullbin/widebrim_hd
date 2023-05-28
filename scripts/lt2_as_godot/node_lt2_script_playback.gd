class_name Lt2GodotScriptBase

extends Node2D

const Utils = preload("res://utils.gd")

signal script_finished;

const Lt2ScreenController 	= preload("res://screen_controller.gd")

var _screen_controller 		: Lt2ScreenController 	= null
var _script 				: Lt2AssetScript 		= null
var _state					: Lt2State				= null
var _idx_instruction 		: int					= 0
var _is_execution_paused 	: bool 					= true

var _debug_key = null
var _delay_by_time_active : bool = false
var _delay_awaiting_touch : bool = false
var _delay_time	: float = 0

func pause_execution():
	_is_execution_paused = true
	
func resume_execution():
	_is_execution_paused 	= false
	_delay_by_time_active 	= false
	_delay_awaiting_touch 	= false

func on_touch():
	if _is_execution_paused and _delay_awaiting_touch:
		resume_execution()

func _do_on_finished():
	script_finished.emit()

func load_init(state : Lt2State, screen_controller : Lt2ScreenController, script : Lt2AssetScript):
	_state = state
	_script = script
	_screen_controller = screen_controller

func _init(state : Lt2State, screen_controller : Lt2ScreenController, script : Lt2AssetScript):
	load_init(state, screen_controller, script)

func _execute_instruction(opcode : int, operands : Array) -> bool:
	match opcode:
		Lt2Constants.SCRIPT_OPERANDS.EXIT_SCRIPT:
			_idx_instruction = _script.get_count_instruction()
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_IN:
			pause_execution()
			_screen_controller.fade_in(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE, Callable(self, "resume_execution"))
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_OUT:
			pause_execution()
			_screen_controller.fade_out(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE, Callable(self, "resume_execution"))
		
		Lt2Constants.SCRIPT_OPERANDS.SET_PLACE:
			_state.set_id_room(operands[0])
		
		Lt2Constants.SCRIPT_OPERANDS.SET_GAME_MODE:
			for key in Lt2Constants.STRING_TO_GAMEMODE_VALUE.keys():
				if Utils.lt2_string_compare(key, operands[0]):
					_state.set_gamemode(Lt2Constants.STRING_TO_GAMEMODE_VALUE.get(key))
		
		Lt2Constants.SCRIPT_OPERANDS.SET_END_GAME_MODE:
			for key in Lt2Constants.STRING_TO_GAMEMODE_VALUE.keys():
				if Utils.lt2_string_compare(key, operands[0]):
					_state.set_gamemode_next(Lt2Constants.STRING_TO_GAMEMODE_VALUE.get(key))
		
		Lt2Constants.SCRIPT_OPERANDS.SET_MOVIE_NUM:
			_state.id_movie = operands[0]
		
		Lt2Constants.SCRIPT_OPERANDS.SET_DRAMA_EVENT_NUM:
			_state.id_event = operands[0]
		
		Lt2Constants.SCRIPT_OPERANDS.SET_AUTO_EVENT_NUM:
			pass	# Intentionally stubbed, no-op
		
		Lt2Constants.SCRIPT_OPERANDS.LOAD_BG:
			_screen_controller.set_background_bs(operands[0])
		
		Lt2Constants.SCRIPT_OPERANDS.LOAD_SUB_BG:
			_screen_controller.set_background_ts(operands[0])
		
		Lt2Constants.SCRIPT_OPERANDS.WAIT_FRAME:
			_delay_time = true
			_delay_by_time_active = operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS
			pause_execution()	
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_IN_ONLY_MAIN:
			pause_execution()
			_screen_controller.fade_in_bs(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE, Callable(self, "resume_execution"))
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_OUT_ONLY_MAIN:
			pause_execution()
			_screen_controller.fade_out_bs(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE, Callable(self, "resume_execution"))
		
		Lt2Constants.SCRIPT_OPERANDS.SET_EVENT_COUNTER:
			_state.flags_event_counter.set_byte(operands[0], operands[1])
		
		Lt2Constants.SCRIPT_OPERANDS.ADD_EVENT_COUNTER:
			_state.flags_event_counter.set_byte(operands[0], _state.flags_event_counter.get_byte(operands[0]) + operands[1])
		
		Lt2Constants.SCRIPT_OPERANDS.OR_EVENT_COUNTER:
			_state.flags_event_counter.set_byte(operands[0], _state.flags_event_counter.get_byte(operands[0]) | operands[1])
		
		Lt2Constants.SCRIPT_OPERANDS.MODIFY_BGPAL:
			_screen_controller.set_background_bs_overlay(operands[3])
		
		Lt2Constants.SCRIPT_OPERANDS.MODIFY_SUB_BGPAL:
			_screen_controller.set_background_ts_overlay(operands[3])
		
		Lt2Constants.SCRIPT_OPERANDS.WAIT_INPUT:
			_delay_awaiting_touch = true
			pause_execution()
		
		Lt2Constants.SCRIPT_OPERANDS.SHAKE_BG:
			_screen_controller.shake_bs(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.SHAKE_SUB_BG:
			_screen_controller.shake_ts(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.WAIT_VSYNC_OR_PEN_TOUCH:
			_delay_awaiting_touch = true
			_delay_time = true
			_delay_by_time_active = operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS
			pause_execution()
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_OUT_FRAME:
			pause_execution()
			_screen_controller.fade_out(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS, Callable(self, "resume_execution"))
		
		Lt2Constants.SCRIPT_OPERANDS.RELEASE_ITEM:
			_state.flags_items.set_bit(operands[0], false)
		
		Lt2Constants.SCRIPT_OPERANDS.DRAW_FRAMES:
			_delay_time = true
			_delay_by_time_active = operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS
			pause_execution()
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_OUT_FRAME_MAIN:
			pause_execution()
			_screen_controller.fade_out_bs(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS, Callable(self, "resume_execution"))
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_IN_FRAME:
			pause_execution()
			_screen_controller.fade_in(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS, Callable(self, "resume_execution"))
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_IN_FRAME_MAIN:
			pause_execution()
			_screen_controller.fade_in_bs(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS, Callable(self, "resume_execution"))
		
		Lt2Constants.SCRIPT_OPERANDS.FLASH_SCREEN:
			# TODO - Timing
			_screen_controller.flash_bs(Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.CHECK_COUNTER_AUTO_EVENT:
			if 0 <= operands[0] and operands[0] < 128:
				if _state.flags_event_counter.get_byte(operands[0]) == operands[1]:
					_state.set_gamemode(Lt2Constants.GAMEMODES.DRAMA_EVENT)
					_state.set_gamemode_next(Lt2Constants.GAMEMODES.DRAMA_EVENT)
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_OUT_FRAME_SUB:
			pause_execution()
			_screen_controller.fade_out_ts(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS, Callable(self, "resume_execution"))
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_IN_FRAME_SUB:
			pause_execution()
			_screen_controller.fade_in_ts(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS, Callable(self, "resume_execution"))
		
		Lt2Constants.SCRIPT_OPERANDS.SET_REPEAT_AUTO_EVENT_ID:
			_state.id_event_held_autoevent = operands[0]
			_state.flags_event_viewed.set_bit(operands[0], false)
		
		Lt2Constants.SCRIPT_OPERANDS.RELEASE_REPEAT_AUTO_EVENT_ID:
			_state.id_event_held_autoevent = -1
			_state.flags_event_viewed.set_bit(operands[0], true)
		
		Lt2Constants.SCRIPT_OPERANDS.SET_FIRST_TOUCH:
			_state.first_touch_enabled = true
		
		Lt2Constants.SCRIPT_OPERANDS.SET_FULL_SCREEN:
			if operands[0] == 1:
				_screen_controller.configure_fullscreen()
			else:
				_screen_controller.configure_room_mode()
		_:
			return false
	return true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not(_is_execution_paused):
		if _idx_instruction >= _script.get_count_instruction():
			pause_execution()
			_do_on_finished()
		else:
			var last_idx = _idx_instruction
			for idx_running in range(last_idx, _script.get_count_instruction()):
				if not(_execute_instruction(_script.get_opcode(idx_running), _script.get_operands(idx_running))):
					_debug_key = Lt2Constants.SCRIPT_OPERANDS.find_key(_script.get_opcode(idx_running))
					if _debug_key != null:
						print("Unimplemented ", _debug_key, " ", _script.get_operands(idx_running))
					else:
						print("Unrecognised ", _script.get_opcode(idx_running), " ", _script.get_operands(idx_running))
					
				_idx_instruction += 1
				if _is_execution_paused:
					break
	else:
		if _delay_by_time_active:
			if _delay_time > 0:
				_delay_time -= _delta
			
			if _delay_time <= 0:
				resume_execution()
