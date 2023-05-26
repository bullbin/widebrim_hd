extends Camera2D

var target_virtual_res : Vector2i = Lt2Constants.RESOLUTION_TARGET

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().connect("size_changed", _on_resize)
	_on_resize()

func _on_resize():
	var size = get_viewport_rect().size
	var viewport_zoom = Vector2(size.x / target_virtual_res.x, size.y / target_virtual_res.y)
	set_zoom(Vector2(min(viewport_zoom.x, viewport_zoom.y), min(viewport_zoom.x, viewport_zoom.y)))
