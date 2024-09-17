class_name Lt2ScreenController

extends Node2D

signal canvas_resize

@export var use_smoothstep 		: bool 	= true

var _timer_ts			: Timer	 	= Timer.new()
var _timer_bs			: Timer		= Timer.new()

@onready var _node_fade_ts 	: ColorRect 	= get_parent().get_node("control_fade/fade_ts")
@onready var _node_fade_bs 	: ColorRect 	= get_parent().get_node("control_fade/fade_bs")
@onready var _node_mask_ts 	: Control		= get_parent().get_node("split_bg/VBoxContainer/mask_ts")
@onready var _node_mask_bs 	: Control		= get_parent().get_node("split_bg/VBoxContainer/mask_bs")
@onready var _node_bg_ts 	: TextureRect 	= get_parent().get_node("split_bg/VBoxContainer/mask_ts/bg_ts")
@onready var _node_bg_bs	: TextureRect 	= get_parent().get_node("split_bg/VBoxContainer/mask_bs/bg_bs")
@onready var _sizer_master	: Control		= get_parent().get_node("split_bg")

var void_bg : ImageTexture = ImageTexture.create_from_image(Image.create(1,1,false,Image.FORMAT_L8))

var _fade_target_bs : float = 1.0
var _fade_target_ts : float = 1.0

var _size_ts : Vector2 = Vector2(0,0)
var _size_bs : Vector2 = Vector2(0,0)

signal fade_btm_done
signal fade_top_done

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
	_timer_ts.timeout.connect(fade_top_done.emit)
	_timer_bs.timeout.connect(fade_btm_done.emit)
	_timer_ts.one_shot = true
	_timer_bs.one_shot = true
	_sizer_master.ratio_changed.connect(_refresh_stored_sizes)
	_refresh_stored_sizes()
	add_child(_timer_bs)
	add_child(_timer_ts)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
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

func input_disable():
	get_viewport().set_disable_input(true)

func input_enable():
	get_viewport().set_disable_input(false)

func set_background_bs(path_bg_relative : String) -> bool:
	var path_bg = path_bg_relative.substr(0, len(path_bg_relative) - 3) + "png"
	path_bg = Lt2Utils.get_asset_path("bg/%s" % path_bg)
	var bg = load(path_bg)

	if bg == null:
		_node_bg_bs.texture = void_bg
		return false
	
	_node_bg_bs.texture = bg
	set_background_bs_overlay(0)
	return true

func set_background_ts(path_bg_relative : String) -> bool:
	var path_bg = path_bg_relative.substr(0, len(path_bg_relative) - 3) + "png"
	path_bg = Lt2Utils.get_asset_path("bg/%s" % path_bg)
	var bg = load(path_bg)
	
	if bg == null:
		_node_bg_ts.texture = void_bg
		return false
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

func shake_bs(_duration : float):
	pass

func shake_ts(_duration : float):
	pass

func flash_bs(_duration : float):
	pass

func _refresh_stored_sizes():
	if _node_mask_ts.size_flags_stretch_ratio == 0:
		_size_bs = _sizer_master.size
	else:
		_size_bs = Vector2(_sizer_master.size.x, _node_mask_bs.custom_minimum_size.y)
	
	_size_ts = Vector2(_sizer_master.size.x, _sizer_master.size.y - _size_bs.y)
	_node_fade_ts.position = get_anchor_loc_ts()
	_node_fade_ts.size = _size_ts
	_node_fade_bs.position = get_anchor_loc_bs()
	_node_fade_bs.size = _size_bs
	
	canvas_resize.emit()

func get_size_bs() -> Vector2:
	return _size_bs

func get_size_ts() -> Vector2:
	return _size_ts

func get_anchor_loc_ts_full_corner() -> Vector2:
	var ts_pos = get_anchor_loc_ts()
	ts_pos += (_size_ts / 2)
	ts_pos -= (Vector2(768, 632) / 2)
	ts_pos.y += _node_bg_ts.position.y
	return ts_pos

func get_anchor_loc_bs_full_corner() -> Vector2:
	var bs_pos = get_anchor_loc_bs()
	bs_pos += (_size_bs / 2)
	bs_pos -= (Vector2(768, 620) / 2)
	return bs_pos

func get_anchor_loc_bs() -> Vector2:
	return get_anchor_loc_ts() + Vector2(0, _size_ts.y)

func get_anchor_loc_ts() -> Vector2:
	return (-_sizer_master.size / 2)

func configure_fullscreen():
	_node_mask_ts.size_flags_stretch_ratio = 0
	_node_mask_ts.hide()
	_node_fade_ts.hide()
	_node_bg_bs.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sizer_master.set_room_mode_state(true)
	_refresh_stored_sizes()

func configure_room_mode():
	_node_mask_ts.size_flags_stretch_ratio = 1
	_node_mask_ts.show()
	_node_fade_ts.show()
	_node_bg_bs.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_sizer_master.set_room_mode_state(true)
	_refresh_stored_sizes()

func configure_event_mode():
	_node_mask_ts.size_flags_stretch_ratio = 1
	_node_mask_ts.show()
	_node_fade_ts.show()
	_node_bg_bs.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_sizer_master.set_room_mode_state(false)
	_refresh_stored_sizes()

# TODO - Both fading functions aren't amazingly safe or well animated
#        This is pretty rudimentary but does the job
func _fade_dual_internal(target : float, duration : float):
	# Attach to whatever screen is still active to ensure callbacks get cleared
	
	# Workaround. Since timers operate independently, one timer lags behind other
	#     by fractions of a millisecond. Fix this by waiting a small period if
	#     permissable.
	
	# TODO - Better workaround preferred.
	if (_timer_ts.time_left + _timer_bs.time_left) > 0:
		var delay = max(_timer_ts.time_left, _timer_bs.time_left)
		if delay < Lt2Constants.TIMING_LT2_TO_MILLISECONDS:
			await get_tree().create_timer(delay).timeout
			
	var bs_ready = _fade_bs_internal(target, duration)
	var ts_ready = _fade_ts_internal(target, duration)
	
	if bs_ready and ts_ready:
		return
	if bs_ready and not(ts_ready):
		await fade_top_done
		return
	if ts_ready and not(bs_ready):
		await fade_btm_done
		return
	
	var prom = Promise.new(Promise.PromiseMode.ALL)
	prom.add_signal(fade_btm_done)
	prom.add_signal(fade_top_done)
	await prom.satisfied

func fade_out_async(duration : float = Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE):
	await _fade_dual_internal(1.0, duration)

func fade_in_async(duration : float = Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE):
	await _fade_dual_internal(0.0, duration)

func fade_bs_async(target : float, duration : float):
	if not(_fade_bs_internal(target, duration)):
		await fade_btm_done

func fade_ts_async(target : float, duration : float):
	if not(_fade_ts_internal(target, duration)):
		await fade_top_done

func _fade_bs_internal(target : float, duration : float) -> bool:
	if not(_timer_bs.is_stopped()):
		# Override previous callable even though its not done
		_timer_bs.stop()
		fade_btm_done.emit()
		_fade_target_bs = target
		_timer_bs.start(duration)
	else:
		# If we're already faded out, don't do anything
		if (_fade_target_bs == target):
			return true
		else:
			# Start timer
			_fade_target_bs = target
			_timer_bs.start(duration)
	return false

func _fade_ts_internal(target : float, duration : float) -> bool:
	if not(_timer_ts.is_stopped()):
		# Override previous callable even though its not done
		_timer_ts.stop()
		fade_top_done.emit()
		_fade_target_ts = target
		_timer_ts.start(duration)
	else:
		# If we're already faded out, don't do anything
		if (_fade_target_ts == target):
			return true
		else:
			# Start timer
			_fade_target_ts = target
			_timer_ts.start(duration)
	return false

func fade_in_bs_async(duration : float = Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE):
	if not(_fade_bs_internal(0.0, duration)):
		await fade_btm_done

func fade_out_bs_async(duration : float = Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE):
	if not(_fade_bs_internal(1.0, duration)):
		await fade_btm_done

func fade_in_ts_async(duration : float = Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE):
	if not(_fade_ts_internal(0.0, duration)):
		await fade_top_done

func fade_out_ts(duration : float = Lt2Constants.SCREEN_CONTROLLER_DEFAULT_FADE):
	if not(_fade_ts_internal(1.0, duration)):
		await fade_top_done
