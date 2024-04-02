extends Node2D

var DEBUG_ARC = preload("res://asset_arc.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	var debug = DEBUG_ARC.new("res://assets/data/ani/eventchr/chr2.spr")
	
	var im_tex = ImageTexture.create_from_image(debug.get_frame(2))

	var node_image = get_node("debug")
	node_image.texture = im_tex


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
