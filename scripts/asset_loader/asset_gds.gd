class_name Lt2AssetScript

extends Object

var _opcodes 	= []
var _operands 	= []

func _init(path_gds : String, read_as_talkscript : bool):
	var file = FileAccess.open(Lt2Utils.get_asset_path(path_gds), FileAccess.READ)
	if file != null:
		var length = file.get_32() + 4
		if read_as_talkscript:
			file.seek(2)
		
		var breakpoint_encountered : bool = false
		var idx_opcode = -1
		var last_type;
		while file.get_position() < length:
			last_type = file.get_16()
			match last_type:
				0:
					if breakpoint_encountered:
						# Stop instruction loading if breakpoint hit.
						break
					else:
						if read_as_talkscript:
							_opcodes.append(last_type)
						else:
							_opcodes.append(file.get_16())
						idx_opcode += 1
						_operands.append([])
				1:
					_operands[idx_opcode].append(file.get_buffer(4).decode_s32(0))
				2:
					_operands[idx_opcode].append(file.get_buffer(4).decode_float(0))
				3:
					_operands[idx_opcode].append(file.get_buffer(file.get_16()).get_string_from_utf8())
				5,8,9,10,11:
					pass
				12:
					breakpoint_encountered = true
				_:
					print("GDS failed to load due to unknown type! Err @ ", file.get_position())
					break

func get_count_instruction() -> int:
	return len(_opcodes)

func get_opcode(idx_cmd : int) -> int:
	if 0 <= idx_cmd and idx_cmd < len(_opcodes):
		return _opcodes[idx_cmd]
	return -1

func get_operands(idx_cmd : int) -> Array:
	if 0 <= idx_cmd and idx_cmd < len(_operands):
		return _operands[idx_cmd]
	return []
