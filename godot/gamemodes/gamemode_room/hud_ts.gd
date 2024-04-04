extends Control

@onready var _node_screen_controller : Lt2ScreenController = get_parent().node_screen_controller
@onready var map_place : Lt2GodotAnimationDeferred = get_node("map_place")
@onready var text_place : Label = get_node("map_place/text_place")
@onready var map_purpose : Lt2GodotAnimationDeferred = get_node("map_purpose")
@onready var text_purpose : Label = get_node("map_purpose/text_purpose")
@onready var toketa_nazo : Lt2GodotAnimationDeferred = get_node("toketa_nazo")
@onready var mapicon : Lt2GodotAnimationDeferred = get_node("mapicon")

var _pos_mapicon : Vector2 = Vector2(0,0)

func _ready():
	_node_screen_controller.canvas_resize.connect(_on_canvas_resized)
	_on_canvas_resized()
	map_place.set_animation_from_index(1)
	text_place.size = map_place.size
	text_place.size.y -= 12
	map_purpose.set_animation_from_index(1)
	text_purpose.size = map_purpose.size
	toketa_nazo.set_animation_from_index(1)
	mapicon.set_animation_from_index(1)

func _on_canvas_resized():
	map_place.set_flippable_position(Vector2(320 - map_place.size.x,
											 _node_screen_controller.get_anchor_loc_ts().y))
	map_purpose.set_flippable_position(Vector2(_node_screen_controller.get_anchor_loc_ts_full_corner().x,
											   _node_screen_controller.get_anchor_loc_ts().y - map_purpose.size.y + _node_screen_controller.get_size_ts().y))
	# TODO - Some logic around language and viewport missing here
	toketa_nazo.set_flippable_position(Vector2(-320, _node_screen_controller.get_anchor_loc_ts().y))
	
	# TODO - Exact positioning unknown, but an offset of ~60 gets applied. Could be safety margin but only applied to bottom screen...
	mapicon.set_flippable_position(_node_screen_controller.get_anchor_loc_ts_full_corner() + _pos_mapicon + Vector2(0, 64))

func set_mapicon_position(pos : Vector2):
	_pos_mapicon = pos
	mapicon.set_flippable_position(_node_screen_controller.get_anchor_loc_ts_full_corner() + _pos_mapicon + Vector2(0, 64))

func get_mapicon_position() -> Vector2:
	return _pos_mapicon
