class_name Lt2DatabasePlaceFlag

extends Object

const COUNT_MAX_SUBROOMS = 16
const COUNT_MAX_ROOMS = 128

# TODO - Maybe always return an entry, even if invalid

class PlaceFlagSubRoomEntry:
	var chapter_start 		: int = 0
	var chapter_end 		: int = 0
	var idx_event_counter 	: int = 0
	var decode_mode 		: int = 0
	var decode_data 		: int = 0
	
	func is_chapter_invalid() -> bool:
		return chapter_start == 0 or chapter_end == 0
	
	func is_event_counter_invalid() -> bool:
		return idx_event_counter == 0

class PlaceFlagRoomEntry:
	var _subrooms : Array[PlaceFlagSubRoomEntry] = []
	
	func add_entry(entry : PlaceFlagSubRoomEntry):
		_subrooms.append(entry)
	
	func get_entry(id_subroom : int) -> PlaceFlagSubRoomEntry:
		if 0 <= id_subroom and id_subroom < len(_subrooms):
			return _subrooms[id_subroom]
		return null

var _rooms : Array[PlaceFlagRoomEntry] = []

func _init(path : String):
	var file = FileAccess.open(Lt2Utils.get_asset_path(path), FileAccess.READ)
	var entry_subroom 	: PlaceFlagSubRoomEntry;
	var entry_room		: PlaceFlagRoomEntry;
	
	if file != null:
		for idx_room in range(COUNT_MAX_ROOMS):
			entry_room = PlaceFlagRoomEntry.new()
			
			for idx_subroom in range(COUNT_MAX_SUBROOMS):
				entry_subroom = PlaceFlagSubRoomEntry.new()
				entry_subroom.chapter_start = file.get_16()
				entry_subroom.chapter_end = file.get_16()
				entry_room.add_entry(entry_subroom)
			
			_rooms.append(entry_room)
		
		for idx_room in range(COUNT_MAX_ROOMS):
			entry_room = _rooms[idx_room]
			
			for idx_subroom in range(COUNT_MAX_SUBROOMS):
				entry_subroom = entry_room.get_entry(idx_subroom)
				entry_subroom.idx_event_counter = file.get_8()
				entry_subroom.decode_mode = file.get_8()
				entry_subroom.decode_data = file.get_8()

func get_room(idx_room : int) -> PlaceFlagRoomEntry:
	if 0 <= idx_room and idx_room < len(_rooms):
		return _rooms[idx_room]
	return null
