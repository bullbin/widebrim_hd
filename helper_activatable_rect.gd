class_name ActivatableRect

extends Control

signal activated

var _is_targetted : bool = false
var _is_enabled : bool = true
var _visualizer : ColorRect = null

func _update_visualizer_visibility():
	if _visualizer != null:
		if _is_enabled:
			_visualizer.show()
		else:
			_visualizer.hide()

func disable():
	_is_enabled = false
	_update_visualizer_visibility()

func enable():
	_is_enabled = true
	_update_visualizer_visibility()

func add_visualizer(color : Color):
	if _visualizer != null:
		remove_visualizer()
	_visualizer = ColorRect.new()
	add_child(_visualizer)
	_visualizer.layout_mode = 1
	_visualizer.anchors_preset = Control.PRESET_FULL_RECT
	_visualizer.set_color(color)
	_visualizer.modulate.a = 0.5
	_update_visualizer_visibility()

func remove_visualizer():
	if _visualizer != null:
		remove_child(_visualizer)
		_visualizer.queue_free()
		_visualizer = null

func _input(event):
	if _is_enabled:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var is_in_range = Rect2(Vector2(), size).has_point(get_local_mouse_position())
			if event.pressed:
				_is_targetted = is_in_range
				if _is_targetted:
					get_viewport().set_input_as_handled()
			else:
				if _is_targetted:
					if is_in_range:
						activated.emit()
					_is_targetted = false
					get_viewport().set_input_as_handled()
