extends Node2D

const LT2_FRAME_INTERVAL : float = 1.0 / 60

const Utils 	= preload("res://utils.gd")
const Lt2Sprite = preload("res://asset_arc.gd")
const Lt2Anim	= preload("res://type_anim.gd")

var _sprite_root 	: Lt2Sprite = null
var _sprite_add 	: Lt2Sprite = null	# Recursive approach not needed - only 1 layer supported!
var _canvas_root	: CanvasGroup = null

var _node_root		: Sprite2D	= null
var _node_add		: Sprite2D 	= null

var _anim_active_root 	: Lt2Anim = null
var _anim_active_add	: Lt2Anim = null

var _idx_current_root 	: int = 0
var _idx_current_add 	: int = 0
var _elapsed_on_root	: float = 0
var _elapsed_on_add		: float = 0
var _add_base_offset	: Vector2 = Vector2(0,0)

var _maximal_size_px	: Vector2i = Vector2i(0,0)

func _init(path_ani_relative : String):
	_canvas_root = CanvasGroup.new()
	add_child(_canvas_root)
	
	var path_anim = Utils.get_asset_root() % ("ani/%s" % path_ani_relative)
	_sprite_root = Lt2Sprite.new(path_anim)
	
	_node_add 	= Sprite2D.new()
	_node_add.region_enabled = true
	_canvas_root.add_child(_node_add)
	
	_node_root 	= Sprite2D.new()
	_node_root.region_enabled = true
	_canvas_root.add_child(_node_root)
	
	var region;
	var base_anim;
	if _sprite_root.get_spritesheet() != null:
		_node_root.texture = ImageTexture.create_from_image(_sprite_root.get_spritesheet())
		for idx_frame in _sprite_root.get_count_frames():
			region = _sprite_root.get_frame_region(idx_frame)
			_maximal_size_px.x = max(region.size.x, _maximal_size_px.x)
			_maximal_size_px.y = max(region.size.y, _maximal_size_px.y)
	
	if _sprite_root.get_subanimation_name() != "":
		_sprite_add = Lt2Sprite.new(Utils.get_asset_root() %
									("ani/sub/%s.spr" % _sprite_root.get_subanimation_name()))
		if _sprite_add.get_spritesheet() != null:
			_node_add.texture = ImageTexture.create_from_image(_sprite_add.get_spritesheet())
			
			# TODO - Negative will not be handled well here
			var max_add_offset = Vector2i(0,0)
			for idx_anim in _sprite_root.get_count_anims():
				base_anim = _sprite_root.get_anim_by_index(idx_anim)
				max_add_offset.x = max(base_anim.get_subanim_offset().x, max_add_offset.x)
				max_add_offset.y = max(base_anim.get_subanim_offset().y, max_add_offset.y)
			
			for idx_frame in _sprite_add.get_count_frames():
				region = _sprite_add.get_frame_region(idx_frame)
				_maximal_size_px.x = max(max_add_offset.x + region.size.x, _maximal_size_px.x)
				_maximal_size_px.y = max(max_add_offset.y + region.size.y, _maximal_size_px.y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_elapsed_on_root += (delta / LT2_FRAME_INTERVAL)
	_elapsed_on_add += (delta / LT2_FRAME_INTERVAL)
	_force_redraw()
	
func _force_apply_anim_visibility_check():
	# If no animation is applied, hide everything
	if _anim_active_root == null or _anim_active_root.get_count_frames() == 0:
		_node_root.hide()
	else:
		_node_root.show()
	if _anim_active_add == null or _anim_active_add.get_count_frames() == 0:
		_node_add.hide()
	else:
		_node_add.show()

func _force_redraw(force_draw_frame : bool = false):
	var was_modified : bool = force_draw_frame
	_force_apply_anim_visibility_check()
	
	# If there is an animation ready, update active frame
	if _anim_active_root != null and _anim_active_root.get_count_frames() > 0:
		# Update active frame index
		# TODO - Protect against duration 0!
		while _elapsed_on_root > _anim_active_root.get_duration(_idx_current_root):
			_elapsed_on_root -= _anim_active_root.get_duration(_idx_current_root)
			_idx_current_root += 1
			if _idx_current_root >= _anim_active_root.get_count_frames():
				_idx_current_root = 0
			was_modified = true
		
		# If it changed, adjust sprite region to match proper region
		if was_modified:
			_node_root.region_rect = _sprite_root.get_frame_region(_anim_active_root.get_frame(_idx_current_root))
			var rect = _sprite_root.get_frame_region(_anim_active_root.get_frame(_idx_current_root))
			_node_root.offset = Vector2(float(rect.size.x) / 2, float(rect.size.y) / 2)
		
	was_modified = force_draw_frame
	if _anim_active_add != null and _anim_active_add.get_count_frames() > 0:
		
		# Update active frame index
		while _elapsed_on_add > _anim_active_add.get_duration(_idx_current_add):
			_elapsed_on_add -= _anim_active_add.get_duration(_idx_current_add)
			_idx_current_add += 1
			if _idx_current_add >= _anim_active_add.get_count_frames():
				_idx_current_add = 0
			was_modified = true
		
		# If it changed, adjust sprite region to match proper region
		if was_modified:
			_node_add.region_rect = _sprite_add.get_frame_region(_anim_active_add.get_frame(_idx_current_add))
			var rect_add = _sprite_add.get_frame_region(_anim_active_root.get_frame(_idx_current_root))
			_node_add.offset = Vector2(float(rect_add.size.x) / 2, float(rect_add.size.y) / 2)
			_node_add.offset += _add_base_offset

func _reset_active_animation():
	if _sprite_add != null:
		if _sprite_add.get_anim_by_index(_anim_active_root.get_subanim_index()) != null:
			_anim_active_add = _sprite_add.get_anim_by_index(_anim_active_root.get_subanim_index())
		_add_base_offset = _anim_active_root.get_subanim_offset()
	
	_idx_current_root = 0
	_idx_current_add = 0
	_elapsed_on_add = 0
	_elapsed_on_root = 0
	_force_redraw(true)
	
	# TODO - Maybe send signal here?

# TODO - Clarify Create an Animation behaviour.
func set_animation_from_name(name_anim : String):
	if _sprite_root != null:
		var anim = _sprite_root.get_anim_by_name(name_anim)
		if anim == null:
			return false
		if anim != _anim_active_root:
			_anim_active_root = anim
			_reset_active_animation()
		return true
	return false

func set_animation_from_index(index : int):
	if _sprite_root != null:
		var anim = _sprite_root.get_anim_by_index(index)
		if anim == null:
			return false
		if anim != _anim_active_root:
			_anim_active_root = anim
			_reset_active_animation()
		return true
	return false

func get_active_animation_index() -> int:
	for idx_anim in range(_sprite_root.get_count_anims()):
		if _sprite_root.get_anim_by_index(idx_anim) == _anim_active_root:
			return idx_anim
	return -1

func get_variable_as_vector_from_name(name_var : String) -> Vector2i:
	var data = _sprite_root.get_variable_by_name(name_var)
	return Vector2i(data[0], data[1])
	
func get_variable_as_vector_from_index(idx_var : int) -> Vector2i:
	var data = _sprite_root.get_variable_by_index(idx_var)
	return Vector2i(data[0], data[1])

func get_maximal_dimensions() -> Vector2i:
	return _maximal_size_px

func set_flip_state(flipped : bool):
	pass

func set_transparency(alpha : float):
	_canvas_root.self_modulate = Color(1,1,1,alpha)
