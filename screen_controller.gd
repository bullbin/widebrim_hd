class_name Lt2ScreenController

extends Node2D

# TODO - Check room draw overlays on how to center images correctly

const Utils 	= preload("res://utils.gd")

@export var use_smoothstep 		: bool 	= true
@export var duration_default 	: float = 4

var _timer_ts_callback 	: Callable 	= Callable()
var _timer_bs_callback 	: Callable 	= Callable()
var _timer_ts			: Timer	 	= Timer.new()
var _timer_bs			: Timer		= Timer.new()

@onready var _node_fade_ts 	: ColorRect 	= get_parent().get_node("control_fade/fade_ts")
@onready var _node_fade_bs 	: ColorRect 	= get_parent().get_node("control_fade/fade_bs")
@onready var _node_bg_ts 	: TextureRect 	= get_parent().get_node("control_bg/bg_ts")
@onready var _node_bg_bs	: TextureRect 	= get_parent().get_node("control_bg/bg_bs")

var _fade_target_bs : float = 1.0
var _fade_target_ts : float = 1.0

func _on_timer_ts_done():
	if not(_timer_ts_callback.is_null()):
		_timer_ts_callback.call()
	_timer_ts_callback = Callable()

func _on_timer_bs_done():
	if not(_timer_bs_callback.is_null()):
		_timer_bs_callback.call()
	_timer_bs_callback = Callable()

func _get_opacity_ts():
	return _node_fade_ts.self_modulate.a
	
func _get_opacity_bs():
	return _node_fade_bs.self_modulate.a
	
func _set_opacity_ts(opacity : float):
	_node_fade_ts.self_modulate.a = opacity
	
func _set_opacity_bs(opacity : float):
	_node_fade_bs.self_modulate.a = opacity

# Called when the node enters the scene tree for the first time.
func _ready():
	_timer_ts.timeout.connect(_on_timer_ts_done)
	_timer_bs.timeout.connect(_on_timer_bs_done)
	_timer_ts.one_shot = true
	_timer_bs.one_shot = true
	add_child(_timer_bs)
	add_child(_timer_ts)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var progress : float = 0
	if _timer_ts.is_stopped():
		_set_opacity_ts(_fade_target_ts)
	else:
		progress = _timer_ts.time_left / _timer_ts.wait_time
		if use_smoothstep:
			_set_opacity_ts(smoothstep(_fade_target_ts, abs(_fade_target_ts - 1), progress))
		else:
			_set_opacity_ts(lerp(_fade_target_ts, abs(_fade_target_ts - 1), progress))
	
	if _timer_bs.is_stopped():
		_set_opacity_bs(_fade_target_bs)
	else:
		progress = _timer_bs.time_left / _timer_bs.wait_time
		if use_smoothstep:
			_set_opacity_bs(smoothstep(_fade_target_bs, abs(_fade_target_bs - 1), progress))
		else:
			_set_opacity_bs(lerp(_fade_target_bs, abs(_fade_target_bs - 1), progress))

func set_background_bs(path_bg_relative : String) -> bool:
	var path_bg = Utils.path_resolve_bg(path_bg_relative)
	path_bg = path_bg.substr(0, len(path_bg) - 3) + "png"
	var bg = Image.load_from_file(path_bg)
	
	if bg == null:
		_node_bg_bs.hide()
		return false
	_node_bg_bs.show()
	bg = ImageTexture.create_from_image(bg)
	_node_bg_bs.texture = bg
	set_background_bs_overlay(0)
	return true

func set_background_ts(path_bg_relative : String) -> bool:
	var path_bg = Utils.path_resolve_bg(path_bg_relative)
	path_bg = path_bg.substr(0, len(path_bg) - 3) + "png"
	var bg = Image.load_from_file(path_bg)
	
	if bg == null:
		_node_bg_ts.hide()
		return false
	_node_bg_ts.show()
	bg = ImageTexture.create_from_image(bg)
	_node_bg_ts.texture = bg
	set_background_ts_overlay(0)
	return true

# TODO - This is not accurate
func set_background_bs_overlay(darkness : int):
	var modulation = float(darkness) / 255
	modulation = min(max(modulation, 0.0), 1.0)
	_node_bg_bs.modulate.a = 1 - modulation

func set_background_ts_overlay(darkness : int):
	var modulation = float(darkness) / 255
	modulation = min(max(modulation, 0.0), 1.0)
	_node_bg_ts.modulate.a = 1 - modulation

func shake_bs(duration : float):
	pass

func shake_ts(duration : float):
	pass

func flash_bs(duration : float):
	pass

# TODO - Both fading functions aren't amazingly safe or well animated
#        This is pretty rudimentary but does the job
func _fade_dual_internal(target : float, duration : float, on_done : Callable = Callable()):
	# Attach to whatever screen is still active to ensure callbacks get cleared
	if not(_timer_ts.is_stopped()):
		_fade_bs_internal(target, duration)
		_fade_ts_internal(target, duration, on_done)
	elif not(_timer_bs.is_stopped()):
		_fade_bs_internal(target, duration, on_done)
		_fade_ts_internal(target, duration)
	else:
		if _get_opacity_bs() == target:
			# Bottom screen is at target, attach to top
			_fade_bs_internal(target, duration)
			_fade_ts_internal(target, duration, on_done)
		else:
			# Attach to bottom screen, doesn't matter anymore
			_fade_bs_internal(target, duration, on_done)
			_fade_ts_internal(target, duration)

func fade_out(duration : float = duration_default, on_done : Callable = Callable()):
	_fade_dual_internal(1.0, duration, on_done)

func fade_in(duration : float = duration_default, on_done : Callable = Callable()):
	_fade_dual_internal(0.0, duration, on_done)

func _fade_bs_internal(target : float, duration : float, on_done : Callable = Callable()):
	if not(_timer_bs.is_stopped()):
		# Override previous callable even though its not done
		_timer_bs.stop()
		_on_timer_bs_done()
		_timer_bs_callback = on_done
		_fade_target_bs = target
		_timer_bs.start(duration)
	else:
		# If we're already faded out, don't do anything
		if (_get_opacity_bs() == target):
			if not(on_done.is_null()):
				on_done.call()
		else:
			_timer_bs_callback = on_done
			_fade_target_bs = target
			_timer_bs.start(duration)

func _fade_ts_internal(target : float, duration : float, on_done : Callable = Callable()):
	if not(_timer_ts.is_stopped()):
		# Override previous callable even though its not done
		_timer_ts.stop()
		_on_timer_ts_done()
		_timer_ts_callback = on_done
		_fade_target_ts = target
		_timer_ts.start(duration)
	else:
		# If we're already faded out, don't do anything
		if (_get_opacity_ts() == target):
			if not(on_done.is_null()):
				on_done.call()
		else:
			# Start timer
			_timer_ts_callback = on_done
			_fade_target_ts = target
			_timer_ts.start(duration)

func fade_in_bs(duration : float = duration_default, on_done : Callable = Callable()):
	_fade_bs_internal(0.0, duration, on_done)

func fade_out_bs(duration : float = duration_default, on_done : Callable = Callable()):
	_fade_bs_internal(1.0, duration, on_done)

func fade_in_ts(duration : float = duration_default, on_done : Callable = Callable()):
	_fade_ts_internal(0.0, duration, on_done)

func fade_out_ts(duration : float = duration_default, on_done : Callable = Callable()):
	_fade_ts_internal(1.0, duration, on_done)
