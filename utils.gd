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
