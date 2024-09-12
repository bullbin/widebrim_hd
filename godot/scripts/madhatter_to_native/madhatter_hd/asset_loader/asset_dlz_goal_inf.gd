class_name DlzGoalInfo

extends DlzGeneric

class DlzEntryGoalInfo:
	extends DlzGeneric.DlzEntry
	var trigger_mokuteki : bool = false
	var idx_goal : int = 0

func _load_entry(buffer : PackedByteArray) -> DlzEntryGoalInfo:
	var output = DlzEntryGoalInfo.new()
	output.id = buffer.decode_u16(0)
	output.trigger_mokuteki = buffer.decode_u16(2) != 0
	output.idx_goal = buffer.decode_u16(4)
	return output
