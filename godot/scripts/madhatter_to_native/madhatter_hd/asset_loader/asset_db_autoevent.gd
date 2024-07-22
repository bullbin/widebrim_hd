class_name Lt2DatabaseAutoEvent

extends RefCounted

const COUNT_MAX_ROOMS 				= 128
const COUNT_MAX_AUTOEVENTS			= 8

class AutoEventRoomEntry:
	var id_event 		: int = -1
	var chapter_start 	: int = -1
	var chapter_end 	: int = -1

class AutoEventRoomCollection:
	var _conditions : Array[AutoEventRoomEntry] = []
	
	func get_entry(chapter : int) -> AutoEventRoomEntry:
		var output : AutoEventRoomEntry = null
		for entry in _conditions:
			if entry.chapter_start <= chapter and entry.chapter_end >= chapter:
				if entry.chapter_start != 0 or entry.chapter_end != 0:
					output = entry
		return output
	
	func add_entry(entry : AutoEventRoomEntry):
		_conditions.append(entry)

var _rooms : Array[AutoEventRoomCollection] = []

func _init(path : String):
	var file = FileAccess.open(Lt2Utils.get_asset_path(path), FileAccess.READ)
	if file != null:

		var room : AutoEventRoomCollection;
		var entry : AutoEventRoomEntry;
		
		for id_room in range(COUNT_MAX_ROOMS):
			room = AutoEventRoomCollection.new()
			
			for id_auto in range(COUNT_MAX_AUTOEVENTS):
				entry = AutoEventRoomEntry.new()
				entry.id_event = file.get_16()
				entry.chapter_start = file.get_16()
				entry.chapter_end = file.get_16()
				file.get_16()
				room.add_entry(entry)
			
			_rooms.append(room)
		
		file.close()

func get_room_entries(id_room : int) -> AutoEventRoomCollection:
	if id_room >= 0 and id_room < len(_rooms):
		return _rooms[id_room]
	return null
