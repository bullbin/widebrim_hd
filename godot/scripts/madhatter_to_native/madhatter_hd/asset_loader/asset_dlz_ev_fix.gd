class_name DlzEventBase

extends DlzGeneric

class DlzEntryEvFix:
	extends DlzGeneric.DlzEntry
	var idx_event_viewed 	: int = 0
	var idx_puzzle_internal : int = 0

func _load_entry(buffer : PackedByteArray) -> DlzEntryEvFix:
	var output = DlzEntryEvFix.new()
	output.id = buffer.decode_s16(0)
	output.idx_puzzle_internal = buffer.decode_u16(2)
	output.idx_event_viewed = buffer.decode_u16(4)
	return output
