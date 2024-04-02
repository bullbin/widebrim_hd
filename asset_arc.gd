extends Node

const LT2_ANIM_COUNT_VARS 	: int = 16
const LT2_ANIM_VAR_LEN		: int = 8

const Lt2Anim = preload("res://type_anim.gd")

var _frames 		: Array[Image] 		= []
var _anims 			: Array[Lt2Anim] 	= []
var _var_names 		: Array[String]		= []
var _var_data		: Array[Array] 		= []

var _sub_anim_name 	: String			= ""
var _sub_offsets	: Array[Vector2i]	= []
var _sub_idx_anim	: Array[int]		= []

func _init(path_arc : String):
	path_arc = path_arc.substr(0, len(path_arc) - 3)
	
	var path_spritesheet = path_arc + "png"
	var path_anim_spec = path_arc + "spr"
	
	# TODO - What happens on bad path?
	var spritesheet = Image.load_from_file(path_spritesheet)
	var file = FileAccess.open(path_anim_spec, FileAccess.READ)
	
	var count_image = file.get_32()
	
	var x_start;
	var y_start;
	var width;
	var height;
	var buffer;
	var img_sprite;
	
	for idx_image in range(count_image):
		buffer = file.get_buffer(8)
		x_start = buffer.decode_s16(0)
		y_start = buffer.decode_s16(2)
		width = buffer.decode_u16(4)
		height = buffer.decode_u16(6)
		
		img_sprite = Image.new()
		img_sprite = img_sprite.create(width, height, false, spritesheet.get_format())
		img_sprite.blit_rect(spritesheet, Rect2i(x_start, y_start, width, height), Vector2i(0,0))
		_frames.append(img_sprite)
	
	file.seek(file.get_position() + 30)
	
	var count_anim = file.get_32()
	var name_anim = ""
	
	for idx_anim in range(count_anim):
		# TODO - Not good. These are either cp1252 or shift-jis encoded (?)
		#        At least Godot handles null termination!
		name_anim = file.get_buffer(30).get_string_from_utf8()
		_anims.append(Lt2Anim.new(name_anim))
	
	var count_keyframes : int;
	var idx_image 	: Array[int] = [];
	var durations 	: Array[int] = [];
	var ordering 	: Array[int] = [];
	var order_sort	: Array[int] = []
	var idx_reorder	: int = 0
	
	for idx_anim in range(count_anim):
		count_keyframes = file.get_32()
		idx_image.clear()
		durations.clear()
		ordering.clear()
		
		for _idx in range(count_keyframes):
			idx_image.append(file.get_32())
		for _idx in range(count_keyframes):
			durations.append(file.get_32())
		for idx in range(count_keyframes):
			ordering.append(file.get_32())
			order_sort.append(ordering[idx])
		
		order_sort.sort()
		for val in order_sort:
			idx_reorder = ordering.find(val)
			_anims[idx_anim].add_frame(idx_image[idx_reorder], durations[idx_reorder])
	
	if file.get_position() < file.get_length():
		if file.get_16() == Lt2Anim.MAGIC_VARIABLE:
			for idx_var in range(LT2_ANIM_COUNT_VARS):
				# TODO - Bad encoding!
				_var_names.append(file.get_buffer(16).get_string_from_utf8())
				_var_data.append([])
				for idx_data in range(LT2_ANIM_VAR_LEN):
					_var_data[idx_var].append(0)
			for idx_data in range(LT2_ANIM_VAR_LEN):
				for idx_var in range(LT2_ANIM_COUNT_VARS):
					_var_data[idx_var][idx_data] = file.get_buffer(2).decode_s16(0)
			
			var sub_x : Array[int] = []
			var sub_y : Array[int] = []
			for _idx in range(count_anim):
				sub_x.append(file.get_buffer(2).decode_s16(0))
			for _idx in range(count_anim):
				sub_y.append(file.get_buffer(2).decode_s16(0))
			for idx in range(count_anim):
				_sub_offsets.append(Vector2i(sub_x[idx], sub_y[idx]))
				_sub_idx_anim.append(file.get_8())
			
			# TODO - Bad encoding!
			_sub_anim_name = file.get_buffer(128).get_string_from_utf8()
	
	#print(_sub_anim_name)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_frame(idx_frame : int):
	return _frames[idx_frame]
