class_name Lt2AssetSprite

extends RefCounted

const LT2_ANIM_COUNT_VARS 	: int = 16
const LT2_ANIM_VAR_LEN		: int = 8
const LT2_ANIM_VAR_EMPTY	: Array[int] = [0,0,0,0,0,0,0,0]

var _spritesheet	: Texture2D			= null
var _frames 		: Array[Rect2i] 	= []
var _anims 			: Array[Lt2TypeAnimation] 	= []
var _var_names 		: Array[String]		= []
var _var_data		: Array[Array] 		= []

var _sub_anim_name 	: String			= ""

func _init(path_arc : String):
	path_arc = path_arc.substr(0, len(path_arc) - 3)
	
	var path_spritesheet = Lt2Utils.get_asset_path("ani/%s" % (path_arc + "png"))
	var path_anim_spec = path_spritesheet.substr(0, len(path_spritesheet) - 3) + "spr"
	
	var file = FileAccess.open(path_anim_spec, FileAccess.READ)
	if file != null:
		_spritesheet = load(path_spritesheet)
		
		var count_image = file.get_32()
		
		var x_start;
		var y_start;
		var width;
		var height;
		var buffer;
		
		for idx_image in range(count_image):
			buffer = file.get_buffer(8)
			x_start = buffer.decode_s16(0)
			y_start = buffer.decode_s16(2)
			width = buffer.decode_u16(4)
			height = buffer.decode_u16(6)
			
			_frames.append(Rect2i(x_start, y_start, width, height))
		
		file.seek(file.get_position() + 30)
		
		var count_anim = file.get_32()
		var name_anim = ""
		
		for idx_anim in range(count_anim):
			# TODO - Not good. These are either cp1252 or shift-jis encoded (?)
			#        At least Godot handles null termination!
			name_anim = file.get_buffer(30).get_string_from_utf8()
			_anims.append(Lt2TypeAnimation.new(name_anim))
		
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
			order_sort.clear()
			
			for idx in range(count_keyframes):
				ordering.append(file.get_32())
				order_sort.append(ordering[idx])
			for _idx in range(count_keyframes):
				durations.append(file.get_32())
			for _idx in range(count_keyframes):
				idx_image.append(file.get_32())
			
			order_sort.sort()
			for val in order_sort:
				idx_reorder = ordering.find(val)
				_anims[idx_anim].add_frame(idx_image[idx_reorder], durations[idx_reorder])
		
		if file.get_position() < file.get_length():
			if file.get_16() == Lt2TypeAnimation.MAGIC_VARIABLE:
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
					_anims[idx].set_subanim_params(Vector2i(sub_x[idx], sub_y[idx]), file.get_8())
				
				# TODO - Bad encoding!
				_sub_anim_name = file.get_buffer(128).get_string_from_utf8()
		
		file.close()

func get_spritesheet() -> Texture2D:
	return _spritesheet

func get_count_frames() -> int:
	return len(_frames)

func get_frame_region(idx_frame : int) -> Rect2i:
	if 0 <= idx_frame and idx_frame < len(_frames):
		return _frames[idx_frame]
	return Rect2i(0,0,0,0)

func get_count_anims() -> int:
	return len(_anims)

func get_anim_by_index(idx_anim : int) -> Lt2TypeAnimation:
	if 0 <= idx_anim and idx_anim < len(_anims):
		return _anims[idx_anim]
	return null

func get_anim_by_name(name_anim : String) -> Lt2TypeAnimation:
	for anim in _anims:
		if Lt2Utils.lt2_string_compare(anim.get_name(), name_anim):
			return anim
	return null

func get_variable_by_index(idx_var : int) -> Array:
	if 0 <= idx_var and idx_var < len(_var_names):
		return _var_data[idx_var]
	return LT2_ANIM_VAR_EMPTY

func get_variable_by_name(name_var : String) -> Array:
	var idx_var = 0
	for name in _var_names:
		if Lt2Utils.lt2_string_compare(name, name_var):
			return _var_data[idx_var]
		idx_var += 1
	return LT2_ANIM_VAR_EMPTY

func get_subanimation_name() -> String:
	return _sub_anim_name
