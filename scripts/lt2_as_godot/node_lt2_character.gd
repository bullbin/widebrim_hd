class_name Lt2GodotCharController

extends Node2D

const PATH_ANIM_CHAR	: String 			= "eventchr/chr%d.arc"
var node_char 			: Lt2GodotAnimation = null
var idx_char 			: int 				= 0
var idx_active_anim		: int 				= 0
var is_talking			: bool				= false

# Verified against game binary
const SLOT_OFFSET = {0:0xf8,
					1:0x180,
					2:0x208,
					3:0xd0,
					4:0x15c,
					5:0x1a1,
					6:0x230,
					7:0x48}
const SLOT_LEFT  : Array[int] = [0,3,4]    # Left side characters need flipping
const SLOT_RIGHT : Array[int] = [2,5,6]

var _fade_to_visible		: bool 		= true
var _fade_duration 			: float		= 0
var _fade_time_remaining 	: float		= 0
var _fade_callback 			: Callable 	= Callable()

func _init(id_char : int):
	idx_char = id_char

# Called when the node enters the scene tree for the first time.
func _ready():
	node_char = Lt2GodotAnimation.new(PATH_ANIM_CHAR % idx_char)
	add_child(node_char)

func set_animation_from_name(name_anim : String):
	if node_char.set_animation_from_name(name_anim):
		idx_active_anim = node_char.get_active_animation_index()
		if is_talking:
			node_char.set_animation_from_index(idx_active_anim + 1)

func set_animation_from_index(idx_anim : int):
	if node_char.set_animation_from_index(idx_anim):
		idx_active_anim = idx_anim
		if is_talking:
			node_char.set_animation_from_index(idx_anim + 1)

func set_talk_state(talking : bool):
	if talking != is_talking:
		if is_talking:
			node_char.set_animation_from_index(idx_active_anim)
		else:
			node_char.set_animation_from_index(idx_active_anim + 1)
		is_talking = talking

func set_char_position(slot : int):
	if 0 <= slot and slot < 8:
		@warning_ignore("integer_division")
		var target_position = Vector2((SLOT_OFFSET[slot] - node_char.get_maximal_dimensions().x / 2),
									   node_char.get_flippable_position().y)

		if slot in SLOT_LEFT:
			node_char.set_flip_state(true)
			target_position.x -= node_char.get_variable_as_vector_from_name("drawoff").x
		else:
			node_char.set_flip_state(false)
			target_position.x += node_char.get_variable_as_vector_from_name("drawoff").x

		if slot == 7:
			target_position.y = 0
		else:
			target_position.y = 524 + node_char.get_variable_as_vector_from_name("drawoff").y
			target_position.y -= node_char.get_maximal_dimensions().y
		
		node_char.set_flippable_position(target_position)

func do_shake(duration : float):
	pass

func set_visibility(showing : bool):
	if showing:
		node_char.set_transparency(1.0)
	else:
		node_char.set_transparency(0.0)

func fade_visibility(showing : bool, duration : float, callback : Callable):
	_fade_to_visible 	= showing
	
	if _fade_duration == 0 and ((showing and node_char.get_transparency() == 1.0) or
								(not(showing) and node_char.get_transparency() == 0.0)):
		# If we're already at correct visibility stage, do callback now
		if not(callback.is_null()):
			callback.call()
	else:
		duration = max(0, duration)
		_fade_duration 			= duration
		_fade_time_remaining 	= duration
		
		# Discard the current callable
		if not(_fade_callback.is_null()):
			_fade_callback.call()
		_fade_callback = Callable()
		
		# If duration is valid, initiate required state and set callable. Else dispose
		if duration > 0:
			set_visibility(not(showing))
			_fade_callback = callback
		else:
			if not(callback.is_null()):
				callback.call()
			set_visibility(showing)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _fade_time_remaining > 0:
		_fade_time_remaining = max(0, _fade_time_remaining - delta)
		
		var strength : float = _fade_time_remaining / _fade_duration
		if strength == 0:
			set_visibility(_fade_to_visible)
			if not(_fade_callback.is_null()):
				_fade_callback.call()
			_fade_callback = Callable()
		else:
			if _fade_to_visible:
				strength = 1.0 - strength
			node_char.set_transparency(strength)
