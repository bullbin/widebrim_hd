class_name DlzGeneric

extends RefCounted

var _entries : Array = []

class DlzEntry:
	var id : int = 0

func find_entry(id : int):
	for entry in _entries:
		if entry.id == id:
			return entry
	return null

func get_entry(idx : int):
	if idx >= 0 and idx < get_count_entries():
		return _entries[idx]
	return null

func get_count_entries() -> int:
	return len(_entries)

func _load_entry(buffer : PackedByteArray):
	return DlzEntry.new()

func _init(path : String):
	var file = FileAccess.open(Lt2Utils.get_asset_path(path), FileAccess.READ)
	if file != null:
		var count_entries = file.get_16()
		var offset_data = file.get_16()
		var size_entry = file.get_32()
		file.seek(offset_data)
		for idx_entry in range(count_entries):
			_entries.append(_load_entry(file.get_buffer(size_entry)))
