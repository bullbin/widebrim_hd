class_name Lt2GodotScriptBase

extends Node2D

signal script_finished;
signal _touch_received;

var _screen_controller 		: Lt2ScreenController 	= null
var _script 				: Lt2AssetScript 		= null
var _state					: Lt2State				= null
var _is_execution_done 		: bool 					= false
var _working 				: bool 					= true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_touch_received.emit()

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
			_is_execution_done = true
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_IN:
			await _screen_controller.fade_in_async()
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_OUT:
			await _screen_controller.fade_out_async()
		
		Lt2Constants.SCRIPT_OPERANDS.SET_PLACE:
			_state.set_id_room(operands[0])
		
		Lt2Constants.SCRIPT_OPERANDS.SET_GAME_MODE:
			for key in Lt2Constants.STRING_TO_GAMEMODE_VALUE.keys():
				if Lt2Utils.lt2_string_compare(key, operands[0]):
					_state.set_gamemode(Lt2Constants.STRING_TO_GAMEMODE_VALUE.get(key))
		
		Lt2Constants.SCRIPT_OPERANDS.SET_END_GAME_MODE:
			for key in Lt2Constants.STRING_TO_GAMEMODE_VALUE.keys():
				if Lt2Utils.lt2_string_compare(key, operands[0]):
					_state.set_gamemode_next(Lt2Constants.STRING_TO_GAMEMODE_VALUE.get(key))
		
		Lt2Constants.SCRIPT_OPERANDS.SET_MOVIE_NUM:
			_state.id_movie = operands[0]
		
		Lt2Constants.SCRIPT_OPERANDS.SET_DRAMA_EVENT_NUM:
			_state.id_event = operands[0]
		
		Lt2Constants.SCRIPT_OPERANDS.SET_AUTO_EVENT_NUM:
			pass	# Intentionally stubbed, no-op
		
		Lt2Constants.SCRIPT_OPERANDS.SET_PUZZLE_NUM:
			_state.set_puzzle_id(operands[0])
		
		Lt2Constants.SCRIPT_OPERANDS.LOAD_BG:
			_screen_controller.set_background_bs(operands[0])
		
		Lt2Constants.SCRIPT_OPERANDS.LOAD_SUB_BG:
			_screen_controller.set_background_ts(operands[0])
		
		Lt2Constants.SCRIPT_OPERANDS.WAIT_FRAME:
			await get_tree().create_timer(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS).timeout
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_IN_ONLY_MAIN:
			await _screen_controller.fade_in_bs_async(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE)
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_OUT_ONLY_MAIN:
			await _screen_controller.fade_out_bs_async(Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE)
		
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
			await _touch_received
			get_viewport().set_input_as_handled()
		
		Lt2Constants.SCRIPT_OPERANDS.SHAKE_BG:
			_screen_controller.shake_bs(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.SHAKE_SUB_BG:
			_screen_controller.shake_ts(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.WAIT_VSYNC_OR_PEN_TOUCH:
			var prom = Promise.new(Promise.PromiseMode.ANY)
			prom.add_signal(_touch_received)
			prom.add_signal(get_tree().create_timer(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS).timeout)
			await prom.satisfied
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_OUT_FRAME:
			await _screen_controller.fade_out_async(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.RELEASE_ITEM:
			_state.flags_items.set_bit(operands[0], false)
		
		Lt2Constants.SCRIPT_OPERANDS.DRAW_FRAMES:
			await get_tree().create_timer(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS).timeout
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_OUT_FRAME_MAIN:
			await _screen_controller.fade_out_bs_async(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_IN_FRAME:
			await _screen_controller.fade_in_async(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_IN_FRAME_MAIN:
			await _screen_controller.fade_in_bs_async(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.FLASH_SCREEN:
			# TODO - Timing
			_screen_controller.flash_bs(Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.CHECK_COUNTER_AUTO_EVENT:
			if 0 <= operands[0] and operands[0] < 128:
				if _state.flags_event_counter.get_byte(operands[0]) == operands[1]:
					_state.set_gamemode(Lt2Constants.GAMEMODES.DRAMA_EVENT)
					_state.set_gamemode_next(Lt2Constants.GAMEMODES.DRAMA_EVENT)
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_OUT_FRAME_SUB:
			await _screen_controller.fade_out_ts_async(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
		Lt2Constants.SCRIPT_OPERANDS.FADE_IN_FRAME_SUB:
			await _screen_controller.fade_in_ts_async(operands[0] * Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	# Instruction processing is async, only permit one _process to run at once
	if _working:
		_working = false
		
		if not(_is_execution_done):
			for idx_instruction in range(_script.get_count_instruction()):
				var known = await _execute_instruction(_script.get_opcode(idx_instruction), _script.get_operands(idx_instruction))
				if not(known):
					var _debug_key = Lt2Constants.SCRIPT_OPERANDS.find_key(_script.get_opcode(idx_instruction))
					if _debug_key != null:
						print("Unimplemented ", _debug_key, " ", _script.get_operands(idx_instruction))
					else:
						print("Unrecognised ", _script.get_opcode(idx_instruction), " ", _script.get_operands(idx_instruction))
				
				if (_is_execution_done):
					break
			
			_is_execution_done = true
			_do_on_finished()
