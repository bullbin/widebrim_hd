extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var node_anim = Lt2GodotAnimation.new("event/twindow.spr")
	add_child(node_anim)
	node_anim.set_animation_from_index(1)
	
	var dimensions = node_anim.get_maximal_dimensions()
	var screen = Lt2Constants.RESOLUTION_TARGET
	
	# todo: 524
	global_position.x = node_anim.get_variable_as_vector_from_index(0).x - screen.x/2
	global_position.y = (screen.y/ 2) - dimensions.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
