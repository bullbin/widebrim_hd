extends Camera2D

var target_virtual_res : Vector2i = Vector2i(768, 1152)

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().connect("size_changed", _on_resize)
	_on_resize()

func _on_resize():
	var size = get_viewport_rect().size
	var zoom = Vector2(size.x / target_virtual_res.x, size.y / target_virtual_res.y)
	set_zoom(Vector2(min(zoom.x, zoom.y), min(zoom.x, zoom.y)))
