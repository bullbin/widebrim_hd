class_name DlzHerbteaEvent

extends DlzGeneric

class DlzEntryHerbteaEvent:
	extends DlzGeneric.DlzEntry
	var idx_herbtea_flag : int = 0

func _load_entry(buffer : PackedByteArray) -> DlzEntryHerbteaEvent:
	var output = DlzEntryHerbteaEvent.new()
	output.id = buffer.decode_u16(0)
	output.idx_herbtea_flag = buffer.decode_u16(2)
	return output
