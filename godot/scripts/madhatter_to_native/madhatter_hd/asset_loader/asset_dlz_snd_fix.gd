class_name DlzSoundSet

extends DlzGeneric

class DlzEntrySoundSet:
	extends DlzGeneric.DlzEntry
	var id_bgm 	: int = 0
	var unk_0 	: int = 0
	var unk_1 	: int = 0

func _load_entry(buffer : PackedByteArray) -> DlzEntrySoundSet:
	var output = DlzEntrySoundSet.new()
	output.id = buffer.decode_u16(0)
	output.id_bgm = buffer.decode_s16(2)
	output.unk_0 = buffer.decode_s16(4)
	output.unk_1 = buffer.decode_s16(6)
	return output
