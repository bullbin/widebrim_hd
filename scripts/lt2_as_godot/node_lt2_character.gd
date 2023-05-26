class_name Lt2GodotCharController

extends Node2D

var node_char 			: Lt2GodotAnimation 	= null
var node_fade			: CanvasFadeController 	= null

const PATH_ANIM_CHAR	: String 	= "eventchr/chr%d.arc"
var idx_char 			: int		= 0
var idx_active_anim		: int 		= 0
var is_talking			: bool		= false

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

func _init(id_char : int):
	idx_char = id_char

# Called when the node enters the scene tree for the first time.
func _ready():
	node_char = Lt2GodotAnimation.new(PATH_ANIM_CHAR % idx_char)
	add_child(node_char)
	node_fade = CanvasFadeController.new()
	node_char.get_canvas_root().add_child(node_fade)

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
		node_fade.fade_visibility(1.0, 0, Callable())
	else:
		node_fade.fade_visibility(0.0, 0, Callable())

func fade_visibility(showing : bool, duration : float, callback : Callable):
	if showing:
		node_fade.fade_visibility(1.0, duration, callback)
	else:
		node_fade.fade_visibility(0.0, duration, callback)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
