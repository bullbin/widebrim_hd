class_name Lt2Utils

# TODO - Not completely accurate (but probably fine...)
#		 Game has a custom comparison table (for NDS at least)
static func lt2_string_compare(str0 : String, str1 : String) -> bool:
	str0 = str0.to_lower()
	str1 = str1.to_lower()
	return str0 == str1

static func get_asset_root() -> String:
	# TODO - Language mixing needs to be done correctly. Maybe offload to script
	return "res://assets/data/%s"

static func path_resolve_bg(path_relative_bg : String) -> String:
	# TODO - Language mixing needs to be done correctly. Maybe offload to script
	return "res://assets/data/%s" % ("bg/%s" % path_relative_bg)

static func get_asset_path(path_relative_root : String) -> String:
	var filepath = "res://assets/data-%s-%s/%s" % [Lt2Constants.LANGUAGE_TO_LANGUAGE[Lt2Constants.CONFIG_GAME_LANGUAGE],
												   Lt2Constants.LANGUAGE_TO_REGION[Lt2Constants.CONFIG_GAME_LANGUAGE],
												   path_relative_root]
	if FileAccess.file_exists(filepath):
		return filepath
	
	filepath = "res://assets/data-%s/%s" % [Lt2Constants.LANGUAGE_TO_LANGUAGE[Lt2Constants.CONFIG_GAME_LANGUAGE],
											path_relative_root]
	if FileAccess.file_exists(filepath):
		return filepath
		
	filepath = "res://assets/data-%s/%s" % [Lt2Constants.LANGUAGE_TO_REGION[Lt2Constants.CONFIG_GAME_LANGUAGE],
								 			path_relative_root]
	if FileAccess.file_exists(filepath):
		return filepath
		
	# Not accurate, we don't scope this all the time
	filepath = "res://assets/data/%s" % path_relative_root
	return filepath

static func get_synth_audio_from_sfx_id(id : int) -> AudioStream:
	var path_sfx = ""
	
	# TODO - Not strictly correct, this doesn't handle edge cases
	# Some IDs are multipart, the SDK can also have 4len IDs but this isn't used
	if id >= 200:
		# SI
		path_sfx = get_asset_path("sound/si/%03d.ogg" % id)
	elif id >= 50:
		# GE
		path_sfx = get_asset_path("sound/ge/%03d.ogg" % id)
	else:
		# SY
		path_sfx = get_asset_path("sound/sy/%03d.ogg" % id)
		
	if path_sfx != "" and ResourceLoader.exists(path_sfx):
		return load(path_sfx)
	else:
		print("Lt2Utils: Audio path resolution failed: %s" % path_sfx)
	return null

static func get_sample_audio_from_sfx_id(id : int) -> AudioStream:
	var path_sfx = ""
	
	# TODO - Not correct
	path_sfx = get_asset_path("sound/ST_%03d.ogg" % id)
		
	if path_sfx != "" and ResourceLoader.exists(path_sfx):
		return load(path_sfx)
	else:
		print("Lt2Utils: Audio path resolution failed: %s" % path_sfx)
	return null
