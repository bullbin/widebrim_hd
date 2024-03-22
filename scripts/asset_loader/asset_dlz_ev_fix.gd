class_name DlzEventBase

extends DlzGeneric

class DlzEntryEvFix:
	extends DlzGeneric.DlzEntry
	var id_event			: int = 0
	var idx_event_viewed 	: int = 0
	var idx_puzzle_internal : int = 0

func _load_entry(buffer : PackedByteArray) -> DlzEntryEvFix:
	var output = DlzEntryEvFix.new()
	output.id_event = buffer.decode_s16(0)
	output.idx_puzzle_internal = buffer.decode_u16(2)
	output.idx_event_viewed = buffer.decode_u16(4)
	return output

func find_entry(id_event : int):
	return super(id_event)

func get_entry(idx : int):
	return super(idx)
