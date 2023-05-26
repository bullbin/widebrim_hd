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
