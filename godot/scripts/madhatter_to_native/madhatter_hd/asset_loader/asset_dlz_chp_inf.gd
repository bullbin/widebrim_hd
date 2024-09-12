class_name DlzChapterInfo

extends DlzGeneric

class DlzEntryChapterInfo:
	extends DlzGeneric.DlzEntry
	var id_event 	: int = 0
	var idx_event_viewed_flag : int = 0
	var id_event_if_viewed : int = 0

func _load_entry(buffer : PackedByteArray) -> DlzEntryChapterInfo:
	var output = DlzEntryChapterInfo.new()
	output.id = buffer.decode_u16(0)
	output.id_event = buffer.decode_u16(0)
	output.idx_event_viewed_flag = buffer.decode_u16(0)
	output.id_event_if_viewed = buffer.decode_u16(0)
	return output
