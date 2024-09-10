extends Control

@onready var anim_twindow : Lt2GodotAnimation = Lt2GodotAnimation.new("tobj/window.spr", get_node("CanvasGroup"))
@onready var anim_icon : Lt2GodotAnimation = Lt2GodotAnimation.new("tobj/icon.spr", get_node("CanvasGroup"))
@onready var anim_cursor : Lt2GodotAnimation = Lt2GodotAnimation.new("cursor_wait.spr", get_node("CanvasGroup"))
@onready var _node_screen_controller : Lt2ScreenController = get_parent().get_parent().node_screen_controller
@onready var _canvas_controller : CanvasFadeController = get_node("CanvasGroup/CanvasFadeController")

@onready var cursor_fade : CanvasAnimFadeController = CanvasAnimFadeController.new()
@onready var node_text = get_node("CanvasGroup/text")

var is_active : bool = false

const SPACING_ICON_X = 16
const SPEED_FADE : float = 0.3
const SPEED_CURSOR_FADE : float = 0.3

const PATH_TOBJ_TEXT = "place/tobj/tobj%d.txt"
const PATH_TOBJ_HINTCOIN = "place/tobj/hintcoin.txt"

signal tobj_overview_done

func _unhandled_input(event: InputEvent) -> void:
	if is_active:
		get_viewport().set_input_as_handled()
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if not(_canvas_controller.is_active()):
				fade_out()

func _ready():
	self.add_child(anim_twindow)
	self.add_child(anim_icon)
	self.add_child(anim_cursor)
	
	anim_cursor.add_child(cursor_fade)
	
	_node_screen_controller.canvas_resize.connect(_on_canvas_resized)
	_canvas_controller.fade_visibility(0.0, 0, Callable())
	
	node_text.position.x = (SPACING_ICON_X * 2) + anim_icon.get_maximal_dimensions().x
	node_text.size.x = anim_twindow.get_maximal_dimensions().x - node_text.position.x
	node_text.size.y = anim_twindow.get_maximal_dimensions().y
	anim_twindow.set_flippable_position(Vector2(0,0))
	
	var icon_position = Vector2i(SPACING_ICON_X, anim_twindow.get_maximal_dimensions().y - anim_icon.get_maximal_dimensions().y)
	icon_position.y /= 2
	anim_icon.set_flippable_position(icon_position)
	
	var wait_position = anim_twindow.get_maximal_dimensions() - anim_cursor.get_maximal_dimensions()
	wait_position.x -= 12
	wait_position.y -= 9
	anim_cursor.set_flippable_position(wait_position)
	
	anim_cursor.set_animation_from_index(1)

func _fade_cursor():
	cursor_fade.fade_visibility(0.5, SPEED_CURSOR_FADE, Callable())

func _on_fade_out_done():
	is_active = false
	tobj_overview_done.emit()

func do_hint_mode():
	is_active = true
	cursor_fade.fade_visibility(0.0, 0, Callable())
	anim_twindow.set_animation_from_index(1)
	anim_icon.set_animation_from_index(3)
	
	var raw_text = FileAccess.open(Lt2Utils.get_asset_path(PATH_TOBJ_HINTCOIN), FileAccess.READ)
	if raw_text != null:
		node_text.set_text(raw_text.get_as_text())
		raw_text.close()
	
	_canvas_controller.fade_visibility(1.0, SPEED_FADE, Callable(_fade_cursor))

func do_tobj_mode(char : int, idx_tobj : int):
	is_active = true
	cursor_fade.fade_visibility(0.0, 0, Callable())
	anim_twindow.set_animation_from_index(1)
	anim_icon.set_animation_from_index(char + 1)
	var raw_text = FileAccess.open(Lt2Utils.get_asset_path(PATH_TOBJ_TEXT % idx_tobj), FileAccess.READ)
	if raw_text != null:
		node_text.set_text(raw_text.get_as_text())
		raw_text.close()
		
	_canvas_controller.fade_visibility(1.0, SPEED_FADE, Callable(_fade_cursor))

func fade_out():
	_canvas_controller.fade_visibility(0.0, SPEED_FADE, Callable(_on_fade_out_done))

func _on_canvas_resized():
	var bs_size = _node_screen_controller.get_size_bs()
	var t_size = anim_twindow.get_maximal_dimensions()
	position = ((bs_size - Vector2(t_size)) / 2)
