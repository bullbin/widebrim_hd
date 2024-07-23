class_name Lt2AssetEventData

extends RefCounted

var map_id_bs 				: int 			= 0
var map_id_ts 				: int 			= 0
var intro_mode 				: int 			= 0
var custom_sound_set		: int 			= 0
var characters 				: Array[int] 	= [0,0,0,0,0,0,0,0]
var characters_slot 		: Array[int] 	= [0,0,0,0,0,0,0,0]
var characters_visibility 	: Array[bool] 	= [false,false,false,false,false,false,false,false]
var characters_idx_anim 	: Array[int] 	= [0,0,0,0,0,0,0,0]

func _init(path_data : String):
	var file = FileAccess.open(Lt2Utils.get_asset_path(path_data), FileAccess.READ)
	if file != null:
		map_id_bs = file.get_16()
		map_id_ts = file.get_16()
		intro_mode = file.get_8()
		custom_sound_set = file.get_8()
		for idx in range(8):
			characters[idx] = file.get_8()
		for idx in range(8):
			characters_slot[idx] = file.get_8()
		for idx in range(8):
			characters_visibility[idx] = file.get_8() == 1
		for idx in range(8):
			characters_idx_anim[idx] = file.get_8()
		
		file.close()
