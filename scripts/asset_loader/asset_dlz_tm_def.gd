class_name DlzTimeDefinition

extends DlzGeneric

class DlzEntryTmDef:
	extends DlzGeneric.DlzEntry
	var count_frames : int = 0

func _load_entry(buffer : PackedByteArray) -> DlzEntryTmDef:
	var output = DlzEntryTmDef.new()
	output.id = buffer.decode_u16(0)
	output.count_frames = buffer.decode_u16(2)
	return output

func find_entry(id : int):
	return super(id)

func get_entry(idx : int):
	return super(idx)
