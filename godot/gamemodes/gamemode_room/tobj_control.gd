extends Control

@onready var anim_twindow : Lt2GodotAnimation = Lt2GodotAnimation.new("tobj/window.spr", get_node("CanvasGroup"))
@onready var anim_icon : Lt2GodotAnimation = Lt2GodotAnimation.new("tobj/icon.spr", get_node("CanvasGroup"))
@onready var anim_cursor : Lt2GodotAnimation = Lt2GodotAnimation.new("cursor_wait.spr", get_node("CanvasGroup"))
@onready var _node_screen_controller : Lt2ScreenController = get_parent().get_parent().node_screen_controller
@onready var _canvas_controller : CanvasFadeController = get_node("CanvasGroup/CanvasFadeController")
@onready var cursor_fade : CanvasFadeController = CanvasFadeController.new()

func _ready():
	var icon_position = Vector2i(16, anim_twindow.get_maximal_dimensions().y - anim_icon.get_maximal_dimensions().y)
	
	icon_position.y /= 2
	var wait_position = anim_twindow.get_maximal_dimensions() - anim_cursor.get_maximal_dimensions()
	wait_position.x -= 12
	wait_position.y -= 9
	
	anim_twindow.set_flippable_position(Vector2(0,0))
	
	anim_twindow.set_animation_from_index(1)
	anim_icon.set_flippable_position(icon_position)
	anim_icon.set_animation_from_index(3)
	
	anim_cursor.set_flippable_position(wait_position)
	anim_cursor.set_animation_from_index(1)
	
	_node_screen_controller.canvas_resize.connect(_on_canvas_resized)
	_canvas_controller.fade_visibility(0.0, 0, Callable())
	do_hint_mode()

func do_hint_mode():
	_node_screen_controller.input_disable()
	_canvas_controller.fade_visibility(1.0, 1.0, Callable())
	anim_cursor.set_transparency(0.5)

func _process(delta):
	anim_twindow._process(delta)
	anim_icon._process(delta)
	anim_cursor._process(delta)
	
func _on_canvas_resized():
	var bs_size = _node_screen_controller.get_size_bs()
	var t_size = anim_twindow.get_maximal_dimensions()
	position = ((bs_size - Vector2(t_size)) / 2)
