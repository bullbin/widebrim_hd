extends Lt2GodotAnimationDeferred

@onready var _node_screen_controller : Lt2ScreenController = get_parent().node_screen_controller

@export var ANIM_DURATION_SECONDS : float = 0.5
@export var ANIM_INTENSITY : float = 100

signal on_hint_coin_anim_finished
var _anchor_position : Vector2 = Vector2(0,0)
var _duration_anim : float = 0
var _anim_active : bool = false
var _phase_anim : float = 0

func _ready():
	super()
	set_animation_from_index(1)
	hide()

func _process(delta):
	if _anim_active:
		_duration_anim = min(_duration_anim + delta, ANIM_DURATION_SECONDS)
		_phase_anim = _duration_anim / ANIM_DURATION_SECONDS
		var pos_adjusted : Vector2 = _node_screen_controller.get_anchor_loc_bs_full_corner() + _anchor_position
		pos_adjusted.y -= sin(PI * _phase_anim) * ANIM_INTENSITY
		pos_adjusted -= size / 2
		set_flippable_position(pos_adjusted)
		
		if _duration_anim >= ANIM_DURATION_SECONDS:
			hide()
			_anim_active = false
			on_hint_coin_anim_finished.emit()
	
	super(delta)

func do_hint_coin_position(absolute_pos_bs : Vector2):
	_anchor_position = absolute_pos_bs
	_duration_anim = 0
	_anim_active = true
	_reset_active_animation()
	show()
