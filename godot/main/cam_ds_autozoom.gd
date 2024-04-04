extends Camera2D

@onready var node_main : Control = get_parent().get_node("split_bg")

const MIN_ASPECT : Vector2i = Vector2i(768,1024)
const MAX_ASPECT : Vector2i = Vector2i(640,1252)

func _ready():
	get_tree().get_root().connect("size_changed", _on_resize)
	_on_resize()

func _on_resize():
	var size = get_viewport_rect().size
	var aspect = float(size.y) / size.x
	
	var aspect_max = float(MAX_ASPECT.y) / MAX_ASPECT.x
	var aspect_min = float(MIN_ASPECT.y) / MIN_ASPECT.x
	var target_res = Vector2i(0,0)

	if aspect < aspect_min:
		# Apply minimum resolution
		target_res = MIN_ASPECT
	elif aspect > aspect_max:
		target_res = MAX_ASPECT
	else:
		var ratio = (aspect - aspect_min) / (aspect_max - aspect_min)
		target_res = (Vector2((MAX_ASPECT - MIN_ASPECT)) * ratio) + Vector2(MIN_ASPECT)
		target_res = Vector2i(target_res)
	
	var viewport_zoom = Vector2(size.x / target_res.x, size.y / target_res.y)
	set_zoom(Vector2(min(viewport_zoom.x, viewport_zoom.y), min(viewport_zoom.x, viewport_zoom.y)))
	
	node_main.size = target_res
	node_main.correct_bottom_screen()
