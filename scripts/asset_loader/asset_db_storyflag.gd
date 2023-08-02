class_name Lt2DatabaseStoryFlag

extends RefCounted

const MAX_COUNT_CHAPTERS = 256
const MAX_COUNT_CONDITIONS = 8

class StoryFlagConditional:
	var type : int = 0
	var data : int = 0

class StoryFlagEntry:
	var chapter : int = 0
	var conditions : Array[StoryFlagConditional] = []

var _flags : Array[StoryFlagEntry] = []

func _init(path : String):
	var file = FileAccess.open(Lt2Utils.get_asset_path(path), FileAccess.READ)
	if file != null:
		var entry : StoryFlagEntry;
		var condition : StoryFlagConditional;
		for idx_chapter in range(MAX_COUNT_CHAPTERS):
			entry = StoryFlagEntry.new()
			entry.chapter = file.get_16()
			for idx_condition in range(MAX_COUNT_CONDITIONS):
				condition = StoryFlagConditional.new()
				condition.type = file.get_8()
				file.get_8()
				condition.data = file.get_16()
				entry.conditions.append(condition)
			_flags.append(entry)

func get_group_index_from_chapter(chapter : int) -> int:
	var idx : int = 0
	for flag in _flags:
		if flag.chapter == chapter:
			return idx
		idx += 1
	return -1

func get_group_at_index(idx : int) -> StoryFlagEntry:
	if 0 <= idx and idx < len(_flags):
		return _flags[idx]
	return null
