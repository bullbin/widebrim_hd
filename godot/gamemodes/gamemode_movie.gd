extends Lt2GamemodeBaseClass

@onready var _node_player : VideoStreamPlayer = get_node("player")
@onready var _node_texture : TextureRect = get_node("workaround_end_frame")

# REF - MovieObject.PlayMovie
# TODO - Buttons, rotation, mode detection (few flags)
# TODO - OGV weird edge bug, video seems slightly scaled with stretched artifact at edge?
#            Is this a Godot problem?

func _ready():
	node_screen_controller.canvas_resize.connect(_on_resize)
	_node_player.finished.connect(_on_end)
	
	node_screen_controller.configure_fullscreen()
	await node_screen_controller.fade_in_async(0)
	_on_resize()
	
	var stream = load(Lt2Utils.get_asset_path("movie/m%d.ogv" % obj_state.id_movie))
	if stream == null:
		_on_end()
		return
		
	_node_texture.texture = load(Lt2Utils.get_asset_path("movie/m%d.png" % obj_state.id_movie))
	
	_node_player.stream = stream
	_node_player.expand = true
	
	SoundController.play_cutscene_audio(obj_state.id_movie)
	_node_player.play()

func _on_end():
	SoundController.stop_sample_sfx()
	await node_screen_controller.fade_out_async(1.0)
	
	node_screen_controller.configure_room_mode()
	obj_state.set_gamemode(obj_state.get_gamemode_next())
	completed.emit()

func _on_resize():
	_node_player.size.x = node_screen_controller.get_size_bs().x
	_node_player.size.y = _node_player.size.x * (9.0/16.0)
	_node_player.position.x = node_screen_controller.get_anchor_loc_bs().x
	_node_player.position.y = node_screen_controller.get_anchor_loc_bs().y + (node_screen_controller.get_size_bs().y - _node_player.size.y) / 2
	
	_node_texture.position = _node_player.position
	_node_texture.size = _node_player.size
