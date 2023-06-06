class_name AddressableBitField

extends RefCounted

var _byte_field : PackedByteArray = PackedByteArray()

func _init(len_bytes : int):
	for _idx in range(len_bytes):
		_byte_field.append(0)

static func from_buffer(buffer : PackedByteArray):
	var output = new(0)
	output._byte_field = buffer.duplicate()
	return output

func to_buffer() -> PackedByteArray:
	return _byte_field.duplicate()

func get_bit(idx_bit : int) -> bool:
	if idx_bit < 0:
		return false
	
	@warning_ignore("integer_division")
	var idx_byte = idx_bit / 8
	idx_bit = idx_bit - (idx_byte * 8)
	var val = get_byte(idx_byte)
	val = (val >> idx_bit) & 0x1
	return val == 1

func set_bit(idx_bit : int, val : bool):
	@warning_ignore("integer_division")
	var idx_byte = idx_bit / 8
	if idx_byte < 0 or idx_byte >= len(_byte_field):
		return
	
	idx_bit = idx_bit - (idx_byte * 8)
	var mask = 1 << idx_bit
	var data = get_byte(idx_byte)
	if val:
		data = data | mask
	else:
		mask = 0xff - mask
		data = data & mask
	set_byte(idx_byte, data)

func get_byte(idx_byte : int) -> int:
	if idx_byte < 0 or idx_byte >= len(_byte_field):
		return 0
	return _byte_field.decode_u8(idx_byte)

func set_byte(idx_byte : int, val : int):
	if idx_byte < 0 or idx_byte >= len(_byte_field):
		return
	val = val & 0xff
	_byte_field.set(idx_byte, val)

func get_bit_length() -> int:
	return len(_byte_field) * 8

func get_byte_length() -> int:
	return len(_byte_field)
