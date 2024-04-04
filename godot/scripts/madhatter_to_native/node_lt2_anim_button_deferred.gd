class_name Lt2GodotAnimatedButtonDeferred

extends Lt2GodotAnimatedButton

@export var path_animation : String = ""
@export var name_anim_rest : String = "off"
@export var name_anim_press : String = "on"
@export var name_anim_click : String = ""
@export var one_shot : bool = false

func _init():
	pass

func _ready():
	_deferred_init_button(path_animation, name_anim_press, name_anim_rest, name_anim_click, one_shot, null)
