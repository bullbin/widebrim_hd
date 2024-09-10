class_name CanvasAnimFadeController

extends Node2D

@onready var parent : Lt2GodotAnimation = get_parent()

@onready var _fade_target	: float 	= parent.get_transparency()
var _fade_start				: float		= 0
var _fade_duration 			: float		= 0
var _fade_time_remaining 	: float		= 0
var _fade_callback 			: Callable 	= Callable()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _fade_time_remaining > 0:
		_fade_time_remaining = max(0, _fade_time_remaining - delta)
		
		var strength 	: float = 1 - (_fade_time_remaining / _fade_duration)
		strength *= (_fade_target - _fade_start)
		parent.set_transparency(_fade_start + strength)
		
		if _fade_time_remaining <= 0:
			if not(_fade_callback.is_null()):
				_fade_callback.call()
			_fade_callback = Callable()

func fade_visibility(target : float, duration : float, callback : Callable):
	if _fade_time_remaining == 0 and target == parent.get_transparency():
		# If we're already at correct visibility stage, do callback now
		if not(callback.is_null()):
			callback.call()
	else:
		duration 				= max(0, duration)
		_fade_start				= parent.get_transparency()
		_fade_duration 			= duration
		_fade_time_remaining 	= duration
		_fade_target 			= target
		
		# Discard the current callable
		if not(_fade_callback.is_null()):
			_fade_callback.call()
		_fade_callback = Callable()
		
		# If duration is valid, initiate required state and set callable. Else dispose
		if duration > 0:
			_fade_callback = callback
		else:
			if not(callback.is_null()):
				callback.call()
			parent.set_transparency(target)

func is_active() -> bool:
	return _fade_time_remaining > 0
