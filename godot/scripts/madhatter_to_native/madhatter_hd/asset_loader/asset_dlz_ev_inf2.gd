class_name DlzEventInfo

extends DlzGeneric

class DlzEntryEvInf2:
	extends DlzGeneric.DlzEntry
	var type_event 			: int = 0
	var data_sound_set 		: int = 0
	var data_puzzle 		: int = 0
	var idx_event_viewed 	: int = 0
	var idx_story_flag 		: int = 0

func _load_entry(buffer : PackedByteArray) -> DlzEntryEvInf2:
	var output = DlzEntryEvInf2.new()
	output.id = buffer.decode_s16(0)
	output.type_event = buffer.decode_s16(2)
	output.data_sound_set = buffer.decode_s16(4)
	output.data_puzzle = buffer.decode_s16(6)
	output.idx_event_viewed = buffer.decode_s16(8)
	output.idx_story_flag = buffer.decode_s16(10)
	return output

func find_entry_no_null(id : int) -> DlzEntryEvInf2:
	var entry = find_entry(id)
	if entry == null:
		entry = DlzEntryEvInf2.new()
	return entry
