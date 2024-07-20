class_name Lt2GodotAnimation

# TODO - Change to animation provider type structure so lookup table can be
#        shared between multiple animations without duplication lookup and spritesheet

extends Control

var _sprite_root 	: Lt2AssetSprite 	= null
var _sprite_add 	: Lt2AssetSprite 	= null	# Recursive approach not needed - only 1 layer supported!
var _canvas_root	: CanvasGroup 		= null	# Render to own canvas is useful for layered sprites
var _is_canvas_external : bool 			= false	# If using an external canvas, we must disable layer blend

var _node_root		: Sprite2D	= null
var _node_add		: Sprite2D 	= null

var _anim_active_root 	: Lt2TypeAnimation = null
var _anim_active_add	: Lt2TypeAnimation = null

var _idx_current_root 	: int = 0
var _idx_current_add 	: int = 0
var _elapsed_on_root	: float = 0
var _elapsed_on_add		: float = 0
var _add_base_offset	: Vector2 = Vector2(0,0)

var _maximal_size_px	: Vector2i = Vector2i(0,0)

var _pos_offset 		: Vector2 = Vector2(0,0)

var _has_init : bool = false

func _init(path_ani_relative : String, render_target : CanvasGroup = null):
	_deferred_init(path_ani_relative, render_target)

func _deferred_init(path_ani_relative : String, render_target : CanvasGroup = null):
	if _has_init:
		return
		
	if render_target == null:
		_canvas_root = CanvasGroup.new()
		add_child(_canvas_root)
	else:
		_canvas_root = render_target
		_is_canvas_external = true
	
	_sprite_root = Lt2AssetSprite.new(path_ani_relative)
	
	_node_add 	= Sprite2D.new()
	_node_add.region_enabled = true
	_canvas_root.add_child(_node_add)
	
	_node_root 	= Sprite2D.new()
	_node_root.region_enabled = true
	_canvas_root.add_child(_node_root)
	
	var region;
	var base_anim;
	if _sprite_root.get_spritesheet() != null:
		_node_root.texture = _sprite_root.get_spritesheet()
		for idx_frame in _sprite_root.get_count_frames():
			region = _sprite_root.get_frame_region(idx_frame)
			_maximal_size_px.x = max(region.size.x, _maximal_size_px.x)
			_maximal_size_px.y = max(region.size.y, _maximal_size_px.y)
	
	if _sprite_root.get_subanimation_name() != "":
		_sprite_add = Lt2AssetSprite.new("sub/%s.spr" % _sprite_root.get_subanimation_name())
		if _sprite_add.get_spritesheet() != null:
			_node_add.texture = _sprite_add.get_spritesheet()
			
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

	size = _maximal_size_px

	_has_init = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _has_init:
		_elapsed_on_root += (delta / Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
		_elapsed_on_add += (delta / Lt2Constants.TIMING_LT2_TO_MILLISECONDS)
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
	if _sprite_root != null:
		for idx_anim in range(_sprite_root.get_count_anims()):
			if _sprite_root.get_anim_by_index(idx_anim) == _anim_active_root:
				return idx_anim
	return -1

func get_variable_as_vector_from_name(name_var : String) -> Vector2i:
	if _sprite_root != null:
		var data = _sprite_root.get_variable_by_name(name_var)
		return Vector2i(data[0], data[1])
	return Vector2i(0,0)
	
func get_variable_as_vector_from_index(idx_var : int) -> Vector2i:
	if _sprite_root != null:
		var data = _sprite_root.get_variable_by_index(idx_var)
		return Vector2i(data[0], data[1])
	return Vector2i(0,0)

func get_maximal_dimensions() -> Vector2i:
	return _maximal_size_px

func set_flippable_position(pos : Vector2):
	if _has_init:
		if _is_canvas_external:
			_node_root.position.x = pos.x + _pos_offset.x
			_node_root.position.y = pos.y
			# TODO - Support subanimation
		else:
			position.x = pos.x + _pos_offset.x
			position.y = pos.y

func get_flippable_position() -> Vector2:
	return Vector2(position.x - _pos_offset.x, position.y)

func set_flip_state(flipped : bool):
	if flipped:
		scale.x = -1
		_pos_offset.x = _maximal_size_px.x
	else:
		scale.x = 1
		_pos_offset.x = 0
	set_flippable_position(position)

func set_transparency(alpha : float):
	if _has_init:
		if _is_canvas_external:
			_node_root.self_modulate.a = alpha
			_node_add.self_modulate.a = alpha
		else:
			_canvas_root.self_modulate.a = alpha

func get_transparency() -> float:
	if _has_init:
		if _is_canvas_external:
			return _node_root.self_modulate.a
		return _canvas_root.self_modulate.a
	return 0.0

func get_canvas_root() -> CanvasGroup:
	return _canvas_root
