# TODO - Reversing on this is not done but widebrim DS plays photo finding sections fine without
#     even loading this database. This is only loosely referenced during room mode and not used
#     anywhere else, I expect the other 8 bytes in this structure to be repeated data

class_name DlzSubPhoto

extends DlzGeneric

class DlzEntrySubPhoto:
	extends DlzGeneric.DlzEntry
	var idx_place : int = 0
	var id_event : int = 0

func _load_entry(buffer : PackedByteArray) -> DlzEntrySubPhoto:
	var output = DlzEntrySubPhoto.new()
	output.id = buffer.decode_u8(0)
	output.idx_place = buffer.decode_u8(1)
	output.id_event = buffer.decode_s16(4)
	return output
