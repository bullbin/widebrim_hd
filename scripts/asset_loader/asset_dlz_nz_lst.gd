class_name DlzNazoList

extends DlzGeneric

class DlzEntryNzLst:
	extends DlzGeneric.DlzEntry
	var id_external : int = 0
	var name 		: String = ""
	var group 		: int = -1

func _load_entry(buffer : PackedByteArray) -> DlzEntryNzLst:
	var output = DlzEntryNzLst.new()
	output.id = buffer.decode_u16(0)
	output.id_external = buffer.decode_u16(2)
	output.name = buffer.slice(4, 84).get_string_from_utf8()
	output.group = buffer.decode_s16(84)
	return output

func find_entry(id : int) -> DlzEntryNzLst:
	return super(id)

func get_entry(idx : int) -> DlzEntryNzLst:
	return super(idx)
