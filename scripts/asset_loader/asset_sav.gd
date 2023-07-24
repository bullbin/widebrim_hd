# Note: I haven't looked much into the HD state system, so types aren't guaranteed
# This is based on the NDS version. Should be very, very similar
class_name Lt2AssetSaveSlot

extends RefCounted

const COUNT_MAX_PUZZLE = 216
const COUNT_MAX_ROOM = 128

class PuzzleState:
	var encountered 	: bool = false
	var solved 			: bool = false
	var picked 			: bool = false
	var nazoba_enabled 	: bool = false
	var decay 			: int = 0
	var hint 			: int = 0
	
	func to_byte() -> int:
		return (int(encountered) + (int(solved) << 1) +
				((decay & 0x03) << 2) + ((hint & 0x03) << 4) +
				(int(nazoba_enabled) << 6) + (int(picked) << 7))
	
	func set_from_byte(val : int):
		encountered 	= (val & 0x01) > 0
		solved 			= (val & 0x02) > 0
		nazoba_enabled 	= (val & 0x40) > 0
		picked 			= (val & 0x80) > 0
		decay 	= (val >> 2) & 0x03
		hint 	= (val >> 4) & 0x03

class PackedRoomManager:
	var _room_data : PackedByteArray = PackedByteArray()
	
	func _init():
		@warning_ignore("integer_division")
		for idx_room in range(COUNT_MAX_ROOM / 2):
			_room_data.append(0)
	
	func _is_data_in_range(idx_place : int, idx_hint : int) -> bool:
		if idx_place < 0 or idx_place >= COUNT_MAX_ROOM:
			return false
		if idx_hint < 0 or idx_hint >= 4:
			return false
		return true
	
	func get_hint_state(idx_place : int, idx_hint : int) -> bool:
		if _is_data_in_range(idx_place, idx_hint):
			@warning_ignore("integer_division")
			var base_val = _room_data[idx_place / 2]
			if idx_place % 2 == 1:
				base_val = base_val >> 4
			base_val = (base_val >> idx_hint) & 0x01
			return base_val > 0
		return false
	
	func set_hint_state(idx_place : int, idx_hint : int, state : bool):
		if _is_data_in_range(idx_place, idx_hint):
			@warning_ignore("integer_division")
			var base_val = _room_data[idx_place / 2]
			if idx_place % 2 == 1:
				idx_hint += 4
			var mask = 1 << idx_hint
			base_val = base_val & (0xff - mask)
			if state:
				base_val += mask
			@warning_ignore("integer_division")
			_room_data.set(_room_data[idx_place / 2], base_val)
	
	func write_contents(file : FileAccess):
		file.store_buffer(_room_data)
	
	func read_contents(file : FileAccess):
		for idx_byte in range(len(_room_data)):
			_room_data.set(idx_byte, file.get_8())

var _name : String 			= "NO NAME"
var _is_complete : bool 	= false

var _puzzle_data : Array[PuzzleState] = []

var flags_event_viewed 	= AddressableBitField.new(128)
var flags_storyflag		= AddressableBitField.new(16)
var flags_event_counter = AddressableBitField.new(128)
var flags_items 		= AddressableBitField.new(1)
var flags_menu_new 		= AddressableBitField.new(2)
var flags_photo_piece 	= AddressableBitField.new(2)
var flags_tutorial 		= AddressableBitField.new(2)
var flags_party_member 	= AddressableBitField.new(1)

var room_hint_state : PackedRoomManager = PackedRoomManager.new()

var _header_time_elapsed 				= 0
var _header_count_puzzle_solved	 		= 0
var _header_count_puzzle_encountered 	= 0
var _header_idx_last_room 				= 0

var hint_coin_encountered 		= 10
var hint_coin_remaining 		= 10

var _id_room 		= 1
var _id_room_sub 	= 0
var _time_elapsed 	= 0
var chapter 		= 5

var _picarats 		= 0

var id_event_held_autoevent = -1
var id_event_immediate		= -1

var objective 		= 100

func _init():
	for _idx in range(COUNT_MAX_PUZZLE):
		_puzzle_data.append(PuzzleState.new())

func get_puzzle_state_external(idx_external : int) -> PuzzleState:
	if idx_external > 0 and idx_external <= len(_puzzle_data):
		return _puzzle_data[idx_external - 1]
	return null

func get_puzzle_solved_count() -> int:
	var output = 0
	for state in _puzzle_data:
		if state.solved:
			output += 1
	return output

func set_id_room(id : int):
	_id_room = id

func get_id_room() -> int:
	return _id_room

func set_id_subroom(id : int):
	_id_room_sub = id

func get_id_subroom() -> int:
	return _id_room_sub

func _signed_to_unsigned(signed : int, max_depth : int) -> int:
	var bound 	: int = 0x01 << (max_depth - 1)
	var clamped : int = min(max(signed, -bound), bound - 1)
	if clamped < 0:
		clamped += 1 << max_depth
	return clamped

func _s16_as_u16(val : int) -> int:
	return _signed_to_unsigned(val, 16)

func _s32_as_u32(val : int) -> int:
	return _signed_to_unsigned(val, 32)

# TODO - Slot
func write_save(path : String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE_READ)
	if file != null:
		file.store_32(0)	# Checksum
		
		flags_event_viewed.write_contents(file)
		flags_storyflag.write_contents(file)
		flags_event_counter.write_contents(file)
		
		for idx_puzzle in range(COUNT_MAX_PUZZLE):
			file.store_8(_puzzle_data[idx_puzzle].to_byte())
		
		room_hint_state.write_contents(file)
		file.store_16(hint_coin_remaining)
		file.store_16(hint_coin_encountered)
		file.store_32(_picarats)
		file.store_32(chapter)
		file.store_32(_id_room)
		file.store_32(_id_room_sub)
		
		file.store_32(0)	# Padding
		
		for _idx_pad in range(60):	# Time(8),CamAvailable(2),CamPiece(20)
			file.store_8(0)			# + Padding(30)
		for _idx_pad in range(67):	# Tea(3),Hamster(35)
			file.store_8(0)			# + Padding(24) + HState(1),Unk(1) + Padding(3)
		
	return file != null

func read_save(path : String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file != null:
		file.seek(4)
		
		flags_event_viewed.read_contents(file)
		flags_storyflag.read_contents(file)
		flags_event_counter.read_contents(file)
		
		for idx_puzzle in range(COUNT_MAX_PUZZLE):
			_puzzle_data[idx_puzzle].set_from_byte(file.get_8())
		
		room_hint_state.read_contents(file)
		hint_coin_remaining = file.get_16()
		hint_coin_encountered = file.get_16()
		_picarats = file.get_32()
		chapter = file.get_32()
		_id_room = file.get_32()
		_id_room_sub = file.get_32()
