class_name DlzSubmapInfo

extends DlzGeneric

class DlzEntrySubmapInfo:
	extends DlzGeneric.DlzEntry
	var idx_place : int = 0
	var chapter : int = 0
	var image : int = 0
	var position : Vector2i = Vector2i(0,0)

func _load_entry(buffer : PackedByteArray) -> DlzEntrySubmapInfo:
	var output = DlzEntrySubmapInfo.new()
	output.id = buffer.decode_u8(0)
	output.idx_place = buffer.decode_u8(1)
	output.chapter = buffer.decode_u16(2)
	output.image = buffer.decode_u8(4)
	output.position.x = buffer.decode_u8(5)
	output.position.y = buffer.decode_u8(6)
	return output
