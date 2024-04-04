class_name Lt2GodotAnimationDeferred

extends Lt2GodotAnimation

@export var path_animation : String = ""

func _init():
	pass

func _ready():
	_deferred_init(path_animation)
