class_name Lt2GodotAnimatedButton

extends Lt2GodotAnimation

signal activated

var _name_anim_on 		: String = ""		# Activated
var _name_anim_off 		: String = ""		# Default
var _name_anim_done 	: String = ""		# Completed
var _do_one_shot 		: bool = false

var _is_enabled 		: bool = true
var _is_targetted 		: bool = false
var _use_custom_size	: bool = false

var _custom_size : Vector2 = Vector2(0,0)

func _init(path_ani_relative : String, ani_on : String = "on", ani_off : String = "off", anim_done : String = "", one_shot : bool = false, render_target : CanvasGroup = null):
	_deferred_init_button(path_ani_relative, ani_on, ani_off, anim_done, one_shot, render_target)

func _deferred_init_button(path_ani_relative : String, ani_on : String = "on", ani_off : String = "off", anim_done : String = "", one_shot : bool = false, render_target : CanvasGroup = null):
	if _has_init:
		return
	
	_deferred_init(path_ani_relative, render_target)
	_name_anim_on = ani_on
	_name_anim_off = ani_off
	
	if anim_done == "":
		_name_anim_done = ani_off
	else:
		_name_anim_done = anim_done
	_do_one_shot = one_shot
	
	set_animation_from_name(_name_anim_off)

func enable():
	_is_enabled = true
	set_animation_from_name(_name_anim_off)

func disable():
	_is_enabled = false

func set_custom_boundary(bound_size : Vector2) -> bool:
	if bound_size.x >= 0 and bound_size.y >= 0:
		_custom_size = bound_size
		_use_custom_size = true
		return true
	return false

func remove_custom_boundary():
	_use_custom_size = false

func _unhandled_input(event):
	if _is_enabled and event is InputEventMouse:
		var size_test;
		if _use_custom_size:
			size_test = _custom_size
		else:
			size_test = size
		
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var is_in_range = Rect2(Vector2(), size_test).has_point(get_local_mouse_position())
			if event.pressed:
				_is_targetted = is_in_range
				if _is_targetted:
					get_viewport().set_input_as_handled()
					set_animation_from_name(_name_anim_on)
			else:
				if _is_targetted:
					get_viewport().set_input_as_handled()
					if is_in_range:
						activated.emit()
						
						if _do_one_shot:
							set_animation_from_name(_name_anim_done)
							disable()
						else:
							set_animation_from_name(_name_anim_off)
					
					_is_targetted = false
		
		elif event is InputEventMouseMotion and _is_targetted:
			var is_in_range = Rect2(Vector2(), size_test).has_point(get_local_mouse_position())
			if is_in_range:
				set_animation_from_name(_name_anim_on)
			else:
				set_animation_from_name(_name_anim_off)
			get_viewport().set_input_as_handled()
