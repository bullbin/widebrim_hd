class_name DlzSoundSet

extends DlzGeneric

class DlzEntrySoundSet:
	extends DlzGeneric.DlzEntry
	var id_bgm 		: int = -1
	var id_sfx_ge 	: int = -1
	var id_sfx_si 	: int = -1

func _load_entry(buffer : PackedByteArray) -> DlzEntrySoundSet:
	var output = DlzEntrySoundSet.new()
	output.id = buffer.decode_u16(0)
	output.id_bgm = buffer.decode_s16(2)
	output.id_sfx_ge = buffer.decode_s16(4)
	output.id_sfx_si = buffer.decode_s16(6)
	return output
