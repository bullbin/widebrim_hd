extends Node2D

var GodotLt2SpriteLoader = preload("res://node_lt2_anim.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	var test = GodotLt2SpriteLoader.new("eventchr/chr2.spr")
	add_child(test)
	test.set_transparency(1.0)
	test.set_animation_from_name("*b1 normal")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
